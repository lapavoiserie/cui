package cui;

import cui.event.Event;
import cui.event.EventLoop;
import cui.event.KeyEvent;

@:autoBuild(cui.macros.StateMacro.build())
class App {
    var eventLoop:EventLoop;

    /**
        What this application owns for as long as it runs.

        An effect an application starts — watching connectivity, a subscription,
        a timer — has to be stopped, and there is exactly one moment every
        backend agrees on: the application is over.

        ```haxe
        lifetime.ownEffect(new Effect(() -> { … Effect.onCleanup(stop); }));
        ```

        **There is no view lifetime here, and that is not an oversight.** A view
        disappearing is observable to Haxe only where Haxe reconciles the tree —
        the push backends — and not at all where the host walks it, which is what
        `sui` and `aui` do. Offering a hook that fired on two backends and stayed
        silent on the others would be worse than not offering one.
    **/
    public final lifetime = new rui.Lifetime();

    public function new() {
        eventLoop = new EventLoop();
    }

    public function body():View {
        return new View();
    }

    public function handleEvent(event:Event):Bool {
        return false;
    }

    public function run():Void {
        eventLoop.run(
            () -> body(),
            (event) -> handleEvent(event)
        );

        // The loop has ended, so anything the application owned for its run is
        // over too. Where no loop returns - sui and aui, whose host owns it -
        // the process is ending instead, and the system reclaims what is left.
        lifetime.release();
    }

    public function quit():Void {
        eventLoop.quit();
    }
}
