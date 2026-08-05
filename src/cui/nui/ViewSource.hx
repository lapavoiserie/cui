package cui.nui;

import cui.View;
import cui.modifiers.ViewModifier;
import nui.Modifier;
import nui.NodeSource;
import nui.PropValue;

/**
	Describes a `cui` view tree through
	[nui's pull contract](https://lapavoiserie.github.io/nui/#/pull-mode).

	The node handle is `cui.View` itself — cui holds a live Haxe tree, exactly as
	`sui` does, so nothing needs copying.

	**What this is for.** cui renders its own tree through `measure`/`render`, so
	it does not need a description layer to draw. This one exists so that a
	*consumer that knows nothing about cui* can walk the tree — a devtool, an
	inspector, a remote protocol, or another renderer. It is also how cui takes
	part in the shared node model rather than being a special case.

	**Scope.** Deliberately a representative subset — containers, a text leaf, a
	control with an action, a box — enough to exercise every corner of the
	vocabulary. Extending it is mechanical.
**/
class ViewSource implements NodeSource<View> {
	final _root:View;
	final _actions:Array<View>;

	public function new(root:View) {
		_root = root;
		_actions = [];
	}

	public function root():View
		return _root;

	/** cui rebuilds by re-running the app's body; there is nothing to invalidate. **/
	public function rebuild():Void {}

	public function typeOf(n:View):String {
		var full = Type.getClassName(Type.getClass(n));
		var dot = full.lastIndexOf(".");
		return dot >= 0 ? full.substr(dot + 1) : full;
	}

	/**
		cui has no notion of node identity: nothing carries a key, and its
		reconciliation is positional because a terminal repaint has no widget
		state to preserve. Always `null` — which the contract allows, and which
		is the honest answer rather than a fabricated one.
	**/
	public function keyOf(n:View):Null<String>
		return null;

	public function childCount(n:View):Int
		return children(n).length;

	public function childAt(n:View, index:Int):View
		return children(n)[index];

	// Box holds its single child in a field rather than in `children`.
	function children(n:View):Array<View> {
		if (Std.isOfType(n, cui.ui.Box)) {
			var b:cui.ui.Box = cast n;
			return b.child != null ? [b.child] : [];
		}
		return n.children;
	}

	// ── Properties ─────────────────────────────────────────────

	public function hasProp(n:View, key:String):Bool
		return props(n).exists(key);

	public function stringProp(n:View, key:String):String
		return PropValueTools.asString(props(n).get(key));

	public function intProp(n:View, key:String):Int
		return PropValueTools.asInt(props(n).get(key));

	public function floatProp(n:View, key:String):Float
		return PropValueTools.asFloat(props(n).get(key));

	public function boolProp(n:View, key:String):Bool
		return PropValueTools.asBool(props(n).get(key));

	/**
		Per-type configuration, as nui properties.

		Note `text` is a plain property here, not a special accessor — that is the
		naming the shared model settled on, and cui had no legacy accessor to
		reconcile.
	**/
	function props(n:View):Map<String, PropValue> {
		var m = new Map<String, PropValue>();
		if (Std.isOfType(n, cui.ui.Text)) {
			var t:cui.ui.Text = cast n;
			m.set("text", PString(t.content));
		} else if (Std.isOfType(n, cui.ui.Button)) {
			var b:cui.ui.Button = cast n;
			m.set("label", PString(b.label));
		} else if (Std.isOfType(n, cui.ui.VStack)) {
			var v:cui.ui.VStack = cast n;
			m.set("spacing", PInt(v.spacing));
		} else if (Std.isOfType(n, cui.ui.HStack)) {
			var h:cui.ui.HStack = cast n;
			m.set("spacing", PInt(h.spacing));
		}
		m.set("focusable", PBool(n.focusable));
		return m;
	}

	// ── Modifiers ──────────────────────────────────────────────

	public function modifierCount(n:View):Int
		return n.modifiers.length;

	public function modifierType(n:View, index:Int):String
		return describe(n.modifiers[index]).type;

	public function modifierFloat(n:View, index:Int, param:Int):Float {
		var f = describe(n.modifiers[index]).floats;
		return (f != null && param < f.length) ? f[param] : 0.0;
	}

	public function modifierString(n:View, index:Int, param:Int):String {
		var s = describe(n.modifiers[index]).strings;
		return (s != null && param < s.length) ? s[param] : "";
	}

	/**
		cui's modifiers are an enum with typed parameters; nui's are a name plus
		positional floats and strings. Mapping is total in this direction — every
		cui modifier has a faithful nui form.
	**/
	function describe(m:ViewModifier):Modifier {
		return switch (m) {
			case ForegroundColor(c): {type: "foregroundColor", strings: [Std.string(c)]};
			case BackgroundColor(c): {type: "backgroundColor", strings: [Std.string(c)]};
			case PaddingAll(v): {type: "padding", floats: [v]};
			case PaddingEdges(t, r, b, l): {type: "padding", floats: [t, r, b, l]};
			case WidthPolicy(p): {type: "width", strings: [Std.string(p)]};
			case HeightPolicy(p): {type: "height", strings: [Std.string(p)]};
			case ContentAlignment(a): {type: "alignment", strings: [Std.string(a)]};
			case Border(s): {type: "border", strings: [Std.string(s)]};
			case _: {type: Std.string(m)};
		}
	}

	// ── Actions ────────────────────────────────────────────────

	/**
		An index into a registry, never a closure — a handler handed to a foreign
		consumer would be untraceable, and on a compiled target invisible to the
		GC. `-1` means the node has no action.
	**/
	public function actionId(n:View):Int {
		if (!Std.isOfType(n, cui.ui.Button)) return -1;
		var i = _actions.indexOf(n);
		if (i >= 0) return i;
		_actions.push(n);
		return _actions.length - 1;
	}

	public function invokeAction(n:View):Void {
		if (Std.isOfType(n, cui.ui.Button)) {
			var b:cui.ui.Button = cast n;
			b.invoke();
		}
	}

	/** Run an action by the identifier `actionId` handed out. **/
	public function invokeActionId(id:Int):Void {
		if (id >= 0 && id < _actions.length) invokeAction(_actions[id]);
	}
}
