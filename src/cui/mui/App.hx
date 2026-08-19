package cui.mui;

import mui.surface.SurfaceDecl;


/**
	`cui`'s conformance for `mui.App`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
/**
	The engine here owns the process: `run()` blocks, and nothing may follow it.

	`mui.macros.Bind` turns this into the `mui_owns_main` flag, so an application
	can write its `main()` once and have it be right everywhere:

	```haxe
	static function main() {
		#if mui_owns_main
		new MyApp().run();
		#end
	}
	```

	Before this the examples wrote `#if (mui_backend == "cui" || mui_backend ==
	"pui")` — a list that a seventh backend would have had to be added to, in
	every application, by hand.
**/
@:muiOwnsMain
@:autoBuild(mui.macros.Surfaces.build())
class App extends cui.App {
    /** App title (informational on cui — terminal has no title bar). **/
    public var appTitle:String = "App";

    /**
        Every surface this application declares: Primary — `body()`, always —
        plus whatever `@:surface` methods collected into `declaredSurfaces()`.
        Override to declare past the sugar: `super.surfaces().concat([…])`.
    **/
    public function surfaces():Array<SurfaceDecl> {
        return [SurfaceDecl.Tree(mui.surface.SurfaceRole.Primary, "body", () -> body())]
            .concat(declaredSurfaces());
    }

    /** What `@:surface` declared. `mui.macros.Surfaces` overrides this on the
        application; the default is the empty answer. **/
    public function declaredSurfaces():Array<SurfaceDecl> return [];

    /** Default event handler: Ctrl+C and q to quit. Override for custom keys. **/
    override function handleEvent(event:cui.event.Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Char("c") if (key.ctrl): quit(); return true;
                    case Char("q"): quit(); return true;
                    default:
                }
            default:
        }
        return false;
    }
}
