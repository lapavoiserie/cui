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
                    // Focused view first, then the tree, then the application.
                    //
                    // The tree pass is what makes a scroll view scroll and a tab
                    // bar change tabs. Both handle arrow keys and neither is
                    // focusable, so with only a focused dispatch their
                    // `handleEvent` was never called: a long page could not be
                    // moved and a tabbed app was stuck on its first tab, with
                    // nothing to press.
                    //
                    // Focus keeps priority, so a text field still owns its own
                    // arrows. Deepest first, so an inner view wins over the
                    // container around it.
                    if (!focusManager.dispatchToFocused(event)) {
                        if (!offerToTree(lastViewTree, event)) {
                            handleEvent(event);
                        } else {
                            StateBase.markDirty();
                        }
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

    /**
        Offer an event to the rendered tree, deepest child first.

        Returns as soon as a view takes it. Nothing here knows which views care
        about which keys -- a view says so by answering `handleEvent`, which is
        the same contract the focused dispatch uses.
    **/
    function offerToTree(view:View, event:Event):Bool {
        if (view == null) return false;
        for (child in view.children) {
            if (offerToTree(child, event)) return true;
        }
        return view.handleEvent(event);
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
