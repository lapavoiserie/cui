package cui.nui;

import cui.View;
import cui.modifiers.ViewModifier;
import cui.render.BorderStyle;
import cui.render.Color;
import nui.Node;
import nui.PropValue;

/**
	Renders **any** [nui](https://lapavoiserie.github.io/nui/) tree in a terminal,
	by turning it into `cui` views and letting `cui` draw them.

	This is the inverse of [`ViewSource`](ViewSource.html), and the useful
	direction. `ViewSource` lets a foreign consumer *read* a cui tree;
	`NodeRenderer` lets cui *display* a tree it did not build — one described by
	another backend, sent over a protocol, or produced by a devtool.

	```haxe
	var view = NodeRenderer.build(node);
	view.render(buffer, area);   // cui draws it, as it draws anything else
	```

	**Why not drive cui's own rendering through the contract instead?** Because
	every one of cui's sixteen components overrides `measure` and `render` —
	close to two thousand lines of layout and drawing that live in the view
	classes. Consuming the contract to draw would mean lifting all of it out for
	no gain to cui, which draws its own trees perfectly well. The contract earns
	its place at the edges: describing outward, and accepting foreign trees
	inward. Not in the middle.

	**Scope.** The same representative subset as `ViewSource`, so the two mirror
	each other. An unknown node type becomes a `Text` naming it rather than
	disappearing — a tree that fails to render should say why on screen.
**/
class NodeRenderer {
	/** Turn a nui node, and its children, into a cui view. **/
	public static function build(node:Node):View {
		if (node == null) return new cui.ui.Text("(null)");

		var kids = [for (c in node.resolveChildren()) build(c)];
		var view = create(node, kids);
		applyModifiers(view, node.modifiers);
		return view;
	}

	static function create(node:Node, kids:Array<View>):View {
		// Everything a control declares about itself, in the one direction and
		// the other, is generated from those declarations -- see cui.nui.Derive.
		// This used to be twenty-four cases facing twenty-two in `Describe`, and
		// the two had already drifted: a `Password` described as an ordinary
		// `TextInput`, and four types `Describe` emits had no case here at all.
		var declared = Derived.BUILDERS.get(node.type);
		if (declared != null) {
			var made = declared(node, kids);
			// The one rule about a RECEIVED tree that no declaration could
			// state: the value is somebody else's, and a node lags a keystroke
			// or two behind while somebody types. Not a dispatch -- one
			// question, asked of whatever came back.
			if (Std.isOfType(made, cui.ui.Input))
				(cast made : cui.ui.Input).receivesValue = true;
			return made;
		}
		// Loud rather than invisible: an unmapped type is a bug to see.
		return new cui.ui.Text("?" + node.type);
	}

	/**
		A callback of any shape becomes the click handler.

		`PCallbackString` matters beyond convenience: an INFLATED tree — one
		that crossed a process boundary through `nui.Snapshot` — carries every
		action in that shape, because the wire kept the types in its table,
		not on the props. A click has no live value to report, so it fires
		with `""` and the far table's recorded shape does the rest. The other
		typed shapes fire with their zero value for the same reason; anything
		else stays a no-op.
	**/
	/**
		An act carrying a position, whatever shape the wire left it in.

		The same tolerance as the others: a tree that crossed a wire carries
		every action as `PCallbackString`, the shapes living in the far table
		and not on the props.
	**/
	public static function index(v:Null<PropValue>):Int->Void {
		var r = PropValueTools.resolve(v);
		if (r == null) return function(_) {};
		return switch (r) {
			case PCallbackInt(fn): fn;
			case PCallbackFloat(fn): function(i:Int) fn(i);
			case PCallbackString(fn): function(i:Int) fn(Std.string(i));
			case PCallback(fn): function(_) fn();
			case _: function(_) {};
		}
	}

	/** An act carrying an amount. `number` under the name the generator uses. **/
	public static function amount(v:Null<PropValue>):Float->Void
		return number(v);

	public static function action(v:Null<PropValue>):Void->Void {
		var r = PropValueTools.resolve(v);
		if (r == null) return function() {};
		return switch (r) {
			case PCallback(fn): fn;
			case PCallbackString(fn): function() fn("");
			case PCallbackBool(fn): function() fn(true);
			case PCallbackFloat(fn): function() fn(0);
			case PCallbackInt(fn): function() fn(0);
			case _: function() {};
		}
	}

	/**
		A callback that carries the index chosen, whatever shape it arrived in.

		The same lesson `pui` learned the hard way, in the other direction: a
		tree that crossed a wire carries a **string** callback for every action,
		so an index handed to one through a `cast` sits in a slot typed String,
		reaches `Std.parseFloat`, and answers NaN. Stringified rather than cast,
		and a picker in a tree built in this process gets the Int it declared.
	**/
	/**
		A callback that carries a `Bool`, whatever shape it arrived in.

		The three below are the same idea as `select`, one per value a control
		reports. Every one of them stringifies rather than casting for a tree
		that crossed a wire, where each action is a string callback: an index,
		a level or a flag cast into that slot reaches `Std.parseFloat` and
		answers NaN, which is how `pui` lost every received slider for a while.
	**/
	public static function flag(v:Null<PropValue>):Bool->Void {
		var r = PropValueTools.resolve(v);
		if (r == null) return function(_) {};
		return switch (r) {
			case PCallbackBool(fn): fn;
			case PCallbackString(fn): function(on) fn(on ? "true" : "false");
			case PCallbackInt(fn): function(on) fn(on ? 1 : 0);
			case PCallbackFloat(fn): function(on) fn(on ? 1 : 0);
			case PCallback(fn): function(_) fn();
			case _: function(_) {};
		}
	}

	/** A callback that carries a level. **/
	public static function number(v:Null<PropValue>):Float->Void {
		var r = PropValueTools.resolve(v);
		if (r == null) return function(_) {};
		return switch (r) {
			case PCallbackFloat(fn): fn;
			case PCallbackInt(fn): function(x) fn(Std.int(x));
			case PCallbackString(fn): function(x) fn(Std.string(x));
			case PCallback(fn): function(_) fn();
			case _: function(_) {};
		}
	}

	/** A callback that carries the whole text, never the key. **/
	public static function words(v:Null<PropValue>):String->Void {
		var r = PropValueTools.resolve(v);
		if (r == null) return function(_) {};
		return switch (r) {
			case PCallbackString(fn): fn;
			case PCallback(fn): function(_) fn();
			case _: function(_) {};
		}
	}

	static function select(v:Null<PropValue>):Int->Void {
		var r = PropValueTools.resolve(v);
		if (r == null) return function(_) {};
		return switch (r) {
			case PCallbackInt(fn): fn;
			case PCallbackFloat(fn): function(at) fn(at);
			case PCallbackString(fn): function(at) fn(Std.string(at));
			case PCallback(fn): function(_) fn();
			case _: function(_) {};
		}
	}

	/**
		Map nui's ordered chain onto cui's `ViewModifier` enum, in order.

		The mapping is partial by nature: nui names a modifier with positional
		parameters, cui's enum is typed. Entries with no cui equivalent are
		skipped — a terminal has no notion of most of them.
	**/
	static function applyModifiers(view:View, modifiers:Array<nui.Modifier>):Void {
		if (modifiers == null) return;
		for (m in modifiers) {
			switch (m.type) {
				case "padding":
					var f = m.floats;
					if (f != null && f.length == 1) {
						view.modifiers.push(PaddingAll(Std.int(f[0])));
					} else if (f != null && f.length == 4) {
						view.modifiers.push(PaddingEdges(Std.int(f[0]), Std.int(f[1]), Std.int(f[2]), Std.int(f[3])));
					}
				case "border":
					view.modifiers.push(Border(BorderStyle.Single));
				case "foregroundColor":
					var c = colorOf(m.strings);
					if (c != null) view.modifiers.push(ForegroundColor(c));
				case "backgroundColor":
					var c = colorOf(m.strings);
					if (c != null) view.modifiers.push(BackgroundColor(c));
				// A terminal CAN cut: render into a buffer of your own and
				// copy back only the window you own, which is what
				// `cui.ui.ScrollView` has done since before there was a canon.
				// This said "no terminal equivalent" and dropped it silently.
				case nui.Modifiers.CLIP:
					view.modifiers.push(Clip);
				case _:
					// No terminal equivalent — skipped on purpose.
			}
		}
	}

	/**
		nui names a colour with a string; cui has a typed `Color` wrapping a
		`NamedColor`. Only the named terminal colours map — a hex value like
		`#00A6BE`, which Silica takes happily, has no faithful equivalent here
		and is skipped rather than approximated.
	**/
	/**
		The colour the wire said, through the canon.

		This used to parse bare names -- `red`, `blue` -- which do not cross;
		`nui.Color` says why. A role is kept as the word and resolved when the
		escape is emitted, so a relayed tree keeps its roles. See
		`cui.nui.Colors`.
	**/
	static function colorOf(strings:Array<String>):Null<Color> {
		if (strings == null || strings.length == 0) return null;
		return Colors.resolve(StringTools.trim(strings[0]));
	}
}
