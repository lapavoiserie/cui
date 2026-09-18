package cui.nui;

import cui.View;
import cui.modifiers.ViewModifier;
import nui.Node;
import nui.PropValue;

/**
	Describes a cui view tree as `nui` nodes — the outward half a detached
	surface needs, mirror of wui's `FromViews`.

	`ViewSource` lets a foreign consumer *walk* a cui tree through the pull
	contract; this produces a `Node` tree outright, which is what
	`nui.Snapshot.project` eats. The distinction matters because the pull
	contract cannot enumerate props — a walker asks by name — while a
	projection must carry everything.

	## The canon

	Types and props are the CANONICAL mui names — `Text`/`text`,
	`Button`/`label`+`onClick`, `Toggle`/`isOn`+`onToggle`,
	`TextInput`/`text`+`onText`, `Slider`/`value`+`onValue` (the change-key
	canon `wui.nui.Bindings` established) — never cui's class names, so a
	snapshot of a cui-served tree and of a wui-served tree look the same on
	the wire and one sink renders both.

	## Describing samples

	A `ConditionalView`'s condition is evaluated here and the taken branch
	described — the branch it stored at construction is stale the moment the
	cell changes, and a snapshot must be the current picture. A `ForEach` is
	spliced into its siblings (a loop is not a thing on screen), and a
	`ViewComponent` is expanded through its `body()`. Liveness is the
	effect *around* the describe: reading the cells here is what subscribes
	the projection to them.

	## Identity

	cui carries no node keys (`ViewSource.keyOf` says why: terminal
	reconciliation is positional, and a fabricated key would be a lie). Keys
	stay null; the receiving renderer's identity is positional too.
**/
@:access(cui.ui.Button)
@:access(cui.ui.Checkbox)
@:access(cui.ui.Slider)
@:access(cui.ui.Picker)
@:access(cui.ui.Input)
@:access(cui.ui.ProgressBar)
@:access(cui.ui.Tabs)
@:access(cui.ui.ListView)
@:access(cui.mui.ConditionalView)
class Describe {
	/** Describe a view tree, or an empty root when there is nothing. **/
	public static function describe(view:View):Node {
		if (view == null) return new Node("VStack");

		// Where one node is expected there are no siblings to become: an
		// expansion at the root is wrapped in the stack it would have filled.
		var expansion:Array<Node> = [];
		if (expanded(view, expansion)) {
			var root = new Node("VStack");
			for (child in expansion) root.child(child);
			return root;
		}
		return node(view);
	}

	/**
		Nodes with no rendering of their own, expanded before the wire sees
		them — the rule every backend's walk follows, on the describe side.
	**/
	static function expanded(view:View, into:Array<Node>):Bool {
		if (Std.isOfType(view, cui.mui.ConditionalView)) {
			var c:cui.mui.ConditionalView = cast view;
			// Sampled live, not the branch construction froze: a describe is
			// the current picture, and the stored children go stale the
			// moment the cell changes.
			var taken = c.condition.get() ? c.thenView : c.elseView;
			if (taken != null && !expanded(taken, into)) into.push(node(taken));
			return true;
		}
		if (isForEach(view)) {
			// cui's ForEach built its children eagerly (the macro read the
			// cell at body() time); they splice as siblings here.
			for (child in view.children) {
				if (child == null) continue;
				if (!expanded(child, into)) into.push(node(child));
			}
			return true;
		}
		if (Std.isOfType(view, cui.ViewComponent)) {
			var body = (cast view : cui.ViewComponent).body();
			if (body != null && body != view && !expanded(body, into)) into.push(node(body));
			return true;
		}
		return false;
	}

	// `cui.ui.ForEach<T>` is generic; Std.isOfType against the raw class
	// answers for every T.
	static function isForEach(view:View):Bool
		return Std.isOfType(view, cui.ui.ForEach);

	/**
		The describer for a view's class, or its nearest declared ancestor's.

		A walk up the chain rather than a chain of `Std.isOfType`, which is the
		whole point: `isOfType` answers by the ORDER the branches were written,
		and here that had already cost something -- `cui.ui.Password` extends
		`cui.ui.Input`, so it fell into the `TextInput` branch and a password
		crossed as an ordinary field, for a receiver to draw in clear.

		`cui.mui.SafeArea` still lands on `VStack`, because on `cui` it IS a
		padded stack and `VStack` is its nearest declared ancestor. Same answer
		as before, reached without an ordered list.
	**/
	static function declaredFor(view:View):Null<View->Node> {
		var cls = Type.getClass(view);
		while (cls != null) {
			var found = Derived.DESCRIBERS.get(Type.getClassName(cls));
			if (found != null) return found;
			cls = cast Type.getSuperClass(cls);
		}
		return null;
	}

	static function node(view:View):Node {
		var out:Node;

		// Three views cross as something other than themselves, each for a
		// reason a declaration could not carry; everything else is generated
		// from what the controls declare -- see cui.nui.Derive.
		//
		// These are asked BEFORE the declarations, and that is the one place
		// order still matters here. Three named exceptions rather than
		// twenty-two ordered branches, and each says why.
		if (Std.isOfType(view, cui.ui.Tabs)) {
			// A snapshot is one picture: the active tab's content, flattened.
			// Carrying every page would describe views the terminal is not
			// showing, and the receiving side has no tab chrome to offer.
			var tabs:cui.ui.Tabs = cast view;
			trace("cui.nui.Describe: TabView flattened to its active tab");
			var active = tabs.activeBinding.get();
			out = new Node("VStack");
			if (active >= 0 && active < tabs.tabs.length) {
				var content = tabs.tabs[active].content;
				var into:Array<Node> = [];
				if (content != null && !expanded(content, into)) into.push(node(content));
				for (child in into) out.child(child);
			}

		} else if (Std.isOfType(view, cui.ui.ListView)) {
			// The selection machinery has no wire canon yet; the rows do.
			var list:cui.ui.ListView = cast view;
			trace("cui.nui.Describe: ListView described as its rows");
			out = new Node("VStack");
			for (item in list.items) out.child(new Node("Text").prop("text", PString(item)));

		} else if (Std.isOfType(view, cui.mui.ZStack)) {
			out = withChildren(new Node("ZStack"), view);

		} else {
			var declared = declaredFor(view);
			if (declared != null) {
				out = declared(view);
			} else {
				// Loud rather than invisible, the NodeRenderer rule in reverse:
				// the receiving side will draw "?Name" and the name says whose.
				var full = Type.getClassName(Type.getClass(view));
				var short = full.substr(full.lastIndexOf(".") + 1);
				out = withChildren(new Node(short), view);
			}
		}

		describeModifiers(view, out);
		return out;
	}

	/**
		Splice a view's children into its node. Called by the generated
		describers, which know a container's children go here and nothing else
		about them.
	**/
	public static function appendChildren(view:View, out:Node):Node
		return withChildren(out, view);

	static function withChildren(out:Node, view:View):Node {
		if (view.children != null) {
			for (child in view.children) {
				if (child == null) continue;
				var into:Array<Node> = [];
				if (expanded(child, into)) {
					for (n in into) out.child(n);
				} else {
					out.child(node(child));
				}
			}
		}
		return out;
	}

	/**
		cui's typed modifier enum as nui's name-plus-positional form.

		Mirror of `ViewSource.describe` — the same mapping stated for the
		pull contract; a change there is a change here. Kept as a copy
		because ViewSource's is an instance method on a walker this file has
		no walker for.
	**/
	static function describeModifiers(view:View, out:Node):Void {
		if (view.modifiers == null) return;
		for (m in view.modifiers) {
			var described:nui.Modifier = switch (m) {
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
			out.modifier(described);
		}
	}
}
