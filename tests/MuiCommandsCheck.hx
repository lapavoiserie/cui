import mui.App;
import mui.View;
import mui.ui.Text;
import mui.surface.Command;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.event.KeyEvent.KeyCode;

/**
	The Commands surface on cui: declared shortcuts run, unmatched keys fall
	through to the quit defaults, and a chord the parser does not understand
	is skipped with a word rather than crashing.

	Runs under the interpreter with the full mui chain — the same shape the
	mui surfaces harness proved out. Judged on the exit code by
	tests/mui-commands.sh.
**/
class MuiCommandsCheck extends App {
	@:state var dummy:Int = 0;

	var added = 0;
	var cleared = 0;
	var exotic = 0;

	override function body():View return new Text("body");

	@:surface(Commands)
	function shortcuts():Array<Command> {
		return [
			new Command("Add", () -> added++).key("ctrl+n"),
			new Command("Clear", () -> cleared++).key("k"),
			new Command("Exotic", () -> exotic++).key("meta+p"), // not a chord cui knows
			new Command("Unbound", () -> exotic++), // no shortcut: declared, unreachable
		];
	}

	static var failed = 0;

	static function check(cond:Bool, msg:String):Void {
		if (!cond) {
			failed++;
			Sys.println("  FAIL " + msg);
		} else {
			Sys.println("  ok   " + msg);
		}
	}

	static function key(code:KeyCode, ctrl = false, alt = false, shift = false):Event {
		return Key(new KeyEvent(code, ctrl, alt, shift));
	}

	static function main() {
		var app = new MuiCommandsCheck();

		check(app.handleEvent(key(Char("n"), true)) && app.added == 1, "ctrl+n runs the command");
		check(app.handleEvent(key(Char("N"), true)) && app.added == 2, "letters match case-insensitively");
		check(app.handleEvent(key(Char("k"))) && app.cleared == 1, "a bare character chord runs");
		check(!app.handleEvent(key(Char("k"), true)), "ctrl+k does not match the bare k chord");
		check(!app.handleEvent(key(Char("x"))), "an unmatched key falls through, unhandled");
		check(app.handleEvent(key(Char("q"))), "q still reaches the quit default");
		check(app.handleEvent(key(Char("c"), true)), "ctrl+c still reaches the quit default");
		check(!app.handleEvent(key(Char("p"))) && app.exotic == 0,
			"an unknown chord is skipped with a word, never matched");
		check(app.added == 2 && app.cleared == 1, "no command ran twice");

		if (failed > 0) {
			Sys.println(failed + " failed");
			Sys.exit(1);
		}
		Sys.println("all good");
	}
}
