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
    public function new() {
        super();
        // The describer is the backend's business — only cui knows where a
        // Checkbox keeps its binding — so the mui layer installs the hook
        // here, the same layering as the other backend hooks. Every mui app
        // sets the same static: idempotent by construction.
        mui.surface.Describe.impl = v -> cui.nui.Describe.describe(cast v);
    }

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

    /** Default event handler: declared commands first, then Ctrl+C and q to
        quit. Override for custom keys. **/
    override function handleEvent(event:cui.event.Event):Bool {
        switch (event) {
            case Key(key):
                if (runCommandFor(key)) return true;
                switch (key.code) {
                    case Char("c") if (key.ctrl): quit(); return true;
                    case Char("q"): quit(); return true;
                    default:
                }
            default:
        }
        return false;
    }

    /**
        The Commands surface, on a terminal: key bindings in this dispatch
        chain — and bindings only. There is no way to *display* the commands
        yet (no overlay, no status bar, no z-order in the buffer), so a
        Command without a shortcut is declared but unreachable here; the
        discoverability half of the role waits for an overlay.

        The command thunks are sampled fresh on every key event rather than
        cached behind an effect: a Model surface maps typed data to a native
        API, and cui's native API for commands *is* this dispatch — there is
        no retained native object to keep in sync, so sampling at use is both
        the cheapest and the always-current answer. Key events are rare;
        a stale cache would not be.

        All CommandSet declarations are consulted in declaration order; the
        first matching shortcut wins.
    **/
    function runCommandFor(key:cui.event.KeyEvent):Bool {
        for (decl in surfaces()) switch (decl) {
            case CommandSet(_, commands):
                for (cmd in commands()) {
                    if (cmd.shortcut == null) continue;
                    if (chordMatches(cmd.shortcut, key)) {
                        cmd.action();
                        return true;
                    }
                }
            case _:
        }
        return false;
    }

    /**
        `"ctrl+n"`, `"alt+x"`, bare `"n"`, and the three named keys a terminal
        can be sure of (`enter`, `escape`/`esc`, `tab`). Modifiers may combine
        (`"ctrl+alt+d"`). Letters match case-insensitively; `shift` is honoured
        only when the chord names it, because a terminal usually encodes shift
        in the character itself.

        A chord this parser does not understand is a tree received as data:
        skipped with a word, once per chord, never a crash.
    **/
    static function chordMatches(chord:String, key:cui.event.KeyEvent):Bool {
        var parts = chord.toLowerCase().split("+");
        var want = parts.pop();
        var ctrl = false, alt = false, shift = false;
        for (mod in parts) switch (mod) {
            case "ctrl": ctrl = true;
            case "alt": alt = true;
            case "shift": shift = true;
            case _: return unknownChord(chord);
        }
        if (want == null || want == "") return unknownChord(chord);
        if (want.length > 1 && want != "enter" && want != "escape" && want != "esc" && want != "tab")
            return unknownChord(chord);

        if (key.ctrl != ctrl || key.alt != alt) return false;
        if (shift && !key.shift) return false;

        return switch (key.code) {
            case Char(c): want.length == 1 && c.toLowerCase() == want;
            case Enter: want == "enter";
            case Escape: want == "escape" || want == "esc";
            case Tab: want == "tab";
            case _: false;
        };
    }

    static var warnedChords = new Map<String, Bool>();

    static function unknownChord(chord:String):Bool {
        if (!warnedChords.exists(chord)) {
            warnedChords.set(chord, true);
            trace('cui: shortcut "' + chord + '" is not a chord this backend understands '
                + '(ctrl+/alt+/shift+ and a character, or enter/escape/tab); the command '
                + 'stays declared but unbound');
        }
        return false;
    }
}
