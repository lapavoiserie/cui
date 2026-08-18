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

        **A view lifetime exists too**, through `lifetime.keep(key, start)`: it
        lasts as long as `body()` keeps declaring that key. Not as long as the
        view is on screen — those differ, and the difference is deliberate. See
        `rui.Lifetime.keep`.
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
            () -> {
                // cui builds its tree eagerly, so it is complete the moment
                // body() returns.
                lifetime.beginPass();
                var tree = body();
                lifetime.endPass();
                return tree;
            },
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
