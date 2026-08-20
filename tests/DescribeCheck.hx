import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import mui.ui.Button;
import mui.ui.Toggle;
import mui.ui.ToggleBinding;
import nui.Node;
import nui.PropValue;
import cui.event.Event;
import cui.event.KeyEvent;

/**
	The whole cui end of the Companion pipe, in one check: a real mui-facade
	tree is DESCRIBED to canonical nodes, PROJECTED to a snapshot (closures
	become ids), carried over the wire as JSON, INFLATED back to nodes whose
	actions send ids, RENDERED by NodeRenderer, and the button is fired
	through the renderer's own event path — the closure must run via the
	ActionTable, across the whole loop.

	Compiled with the full mui chain, judged on the exit code.

	    ./tests/describe.sh
**/
class DescribeCheck extends App {
	static var fails = 0;

	static function check(label:String, ok:Bool) {
		if (!ok) fails++;
		Sys.println((ok ? "  ok   " : "  FAIL ") + label);
	}

	@:state var lit:Bool = false;

	override function body():View {
		return new VStack([
			new Text("hello"),
			new Button("Go", () -> taps.push("go")),
			new Toggle("Lamp", (lit : ToggleBinding)),
		], 8);
	}

	static var taps:Array<String> = [];

	static function main() {
		Sys.println("cui — describe, and the whole Companion pipe");

		// The app's constructor installs the hook; describe through it, the
		// way a projector would.
		var app = new DescribeCheck();
		var described = mui.surface.Describe.describe(app.body());
		check("the hook answers", described != null);

		// --- The canon ---
		check("a stack describes with its spacing", described.type == "VStack"
			&& PropValueTools.asInt(described.props.get("spacing")) == 1);
		check("Text carries text", described.children[0].type == "Text"
			&& PropValueTools.asString(described.children[0].props.get("text")) == "hello");
		var btn = described.children[1];
		check("Button carries label and onClick", btn.type == "Button"
			&& PropValueTools.asString(btn.props.get("label")) == "Go"
			&& btn.props.get("onClick") != null);
		check("onClick is a callback prop", switch (PropValueTools.resolve(btn.props.get("onClick"))) {
			case PCallback(_): true;
			case _: false;
		});
		var tog = described.children[2];
		check("Toggle follows the change-key canon (isOn/onToggle)", tog.type == "Toggle"
			&& PropValueTools.asBool(tog.props.get("isOn")) == false
			&& tog.props.get("onToggle") != null);

		// A described two-way control writes through to the cell.
		switch (PropValueTools.resolve(tog.props.get("onToggle"))) {
			case PCallbackBool(fn): fn(true);
			case _:
		}
		check("a described binding writes back to the state", app.lit.get() == true);

		// --- The pipe: project -> wire -> inflate -> render -> fire ---
		var table = new nui.Snapshot.ActionTable();
		var snap = nui.Snapshot.project(described, table);
		var wire = nui.Snapshot.toJson(snap);
		var far = nui.Snapshot.fromJson(wire);
		check("the snapshot carries the action ids", far.children[1].actions.get("onClick") != null);

		// The far side: invoke crosses back into the table (a channel in a
		// real deployment; direct here — the table is the contract).
		var inflated = nui.Snapshot.inflate(far, (id, arg) -> table.invoke(id, arg));
		var view = cui.nui.NodeRenderer.build(inflated);

		// Fire the button through the RENDERER's own event path: find it and
		// press Enter, the way a terminal user would.
		var button = findButton(view);
		check("the renderer built the button", button != null);
		if (button != null) {
			button.handleEvent(Key(new KeyEvent(Enter)));
		}
		check("a remote-shaped tap crossed the whole pipe", taps.length == 1 && taps[0] == "go");

		Sys.println(fails == 0 ? "\nall good" : '\n$fails failed');
		Sys.exit(fails == 0 ? 0 : 1);
	}

	static function findButton(view:cui.View):Null<cui.ui.Button> {
		if (Std.isOfType(view, cui.ui.Button)) return cast view;
		if (view.children != null) for (child in view.children) {
			var found = findButton(child);
			if (found != null) return found;
		}
		return null;
	}
}
