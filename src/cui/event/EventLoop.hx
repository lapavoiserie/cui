package cui.event;

import cui.backend.Backend;
import cui.backend.CrossTerminal;
import cui.focus.FocusManager;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;
import cui.render.Renderer;
import cui.View;
import cui.state.State;

class EventLoop {
    var backend:Backend;
    var shouldQuit:Bool;
    var previousBuffer:Buffer;
    var firstFrame:Bool;
    var focusManager:FocusManager;
    var lastViewTree:View;

    public function new(?backend:Backend) {
        this.backend = backend != null ? backend : CrossTerminal.create();
        shouldQuit = false;
        firstFrame = true;
        focusManager = new FocusManager();
        View.focusManager = focusManager;
    }

    public function run(bodyFn:Void->View, handleEvent:Event->Bool):Void {
        backend.enterRawMode();
        // Asked before the alternate screen and before anything is drawn: the
        // terminal answers on the input the application is about to own, and
        // this is the one moment nobody else is reading it. See
        // `cui.term.Graphics`.
        cui.term.Graphics.detect(data -> backend.write(data), timeout -> backend.readByte(timeout));
        backend.enterAlternateScreen();
        backend.hideCursor();
        backend.enableMouseCapture();

        var size = backend.getSize();
        previousBuffer = new Buffer(size.width, size.height);

        // Initial render
        StateBase.clearDirty();
        renderFrame(bodyFn, size);

        while (!shouldQuit) {
            var event = backend.pollEvent(16); // ~60fps

            // Let Haxe's own scheduled work run. Without this a `haxe.Timer`
            // created by an application never fires — silently: no error, no
            // warning, just nothing happening, for ever. The entry point pumps
            // it *after* main() returns, and an application that never returns
            // from run() never gets there.
            //
            // Which loop to pump depends on the target, and getting it wrong
            // looks identical to not pumping at all. On a threaded target -
            // every hxcpp build - `haxe.Timer` uses the current **thread's**
            // event loop (`#if (target.threaded && !cppia)` in haxe/Timer.hx),
            // not `haxe.MainLoop`; on the others it is MainLoop. Both are
            // pumped, because a wrong guess here costs an afternoon.
            //
            // Found by an example that watched the network on a one-second
            // timer and reported no change at all while the link was taken
            // down and brought back.
            #if (target.threaded && !cppia)
            sys.thread.Thread.current().events.progress();
            #else
            @:privateAccess haxe.MainLoop.tick();
            #end

            // Check for resize
            var newSize = backend.getSize();
            if (newSize.width != size.width || newSize.height != size.height) {
                size = newSize;
                previousBuffer = new Buffer(size.width, size.height);
                firstFrame = true;
                renderFrame(bodyFn, size);
            }

            if (event != null) {
                // Handle built-in: Ctrl+C
                switch (event) {
                    case Key(key):
                        switch (key.code) {
                            case Char(c):
                                if (c == "c" && key.ctrl) {
                                    quit();
                                    continue;
                                }
                            default:
                        }
                    default:
                }

                // Handle mouse clicks — focus the clicked view
                switch (event) {
                    case Mouse(mouse):
                        if (mouse.action == Press && mouse.button == Left) {
                            handleMouseClick(mouse.x, mouse.y);
                        }
                    default:
                }

                // Handle focus navigation (Tab / Shift-Tab)
                if (!focusManager.handleNavigation(event)) {
                    // The focused view, then the application. Nothing between
                    // them.
                    //
                    // There used to be a pass over the whole rendered tree
                    // here, offering what focus declined to any view that would
                    // take it. Every view in this library that handles a key is
                    // focusable -- Button, Checkbox, Input, Slider, Picker, and
                    // ScrollView, Tabs and ListView too -- so that pass could
                    // only ever reach a view BEHIND focus's back, which is what
                    // it did: on a panel of five pickers, Right pressed on the
                    // fifth moved the first. Benjamin saw it.
                    //
                    // It was added to make a scroll view scroll and a tab bar
                    // change tabs, on the premise that neither was focusable.
                    // They both were, and had been for months. The real cause
                    // was the other half of that same commit: `Tabs` renders
                    // its content from `tabs` and not from `children`, so the
                    // focus ring -- which walks `children` -- never reached the
                    // scroll view inside a tab. That fix stays; this one goes.
                    if (!focusManager.dispatchToFocused(event)) {
                        handleEvent(event);
                    }
                } else {
                    StateBase.markDirty();
                }
            }

            // Re-render if state changed
            if (StateBase.isDirty()) {
                StateBase.clearDirty();
                renderFrame(bodyFn, size);
            }
        }

        backend.disableMouseCapture();
        backend.showCursor();
        backend.leaveAlternateScreen();
        backend.leaveRawMode();
    }

    function handleMouseClick(x:Int, y:Int):Void {
        if (lastViewTree == null) return;

        // Find the deepest focusable view at (x, y)
        var target = hitTest(lastViewTree, x, y);
        if (target != null) {
            // Focus this view
            focusManager.focusView(target);
            StateBase.markDirty();
        }
    }

    function hitTest(view:View, x:Int, y:Int):Null<View> {
        // Check children first (deeper match wins)
        for (child in view.children) {
            var hit = hitTest(child, x, y);
            if (hit != null) return hit;
        }
        // Check this view
        if (view.focusable && view.frame.contains(x, y)) {
            return view;
        }
        return null;
    }

    function renderFrame(bodyFn:Void->View, size:Size):Void {
        var viewTree = bodyFn();
        lastViewTree = viewTree;

        // Build focus ring from current view tree
        focusManager.buildFocusRing(viewTree);

        var currentBuffer = new Buffer(size.width, size.height);
        var area = new Rect(0, 0, size.width, size.height);

        viewTree.render(currentBuffer, area);

        if (firstFrame) {
            Renderer.renderFull(currentBuffer, backend);
            firstFrame = false;
        } else {
            Renderer.render(previousBuffer, currentBuffer, backend);
        }

        previousBuffer = currentBuffer;
    }

    public function quit():Void {
        shouldQuit = true;
    }
}
