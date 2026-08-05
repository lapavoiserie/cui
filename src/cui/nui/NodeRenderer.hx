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
		var props = node.props;
		return switch (node.type) {
			case "Text":
				new cui.ui.Text(PropValueTools.asString(props.get("text")));

			case "VStack":
				new cui.ui.VStack(kids, PropValueTools.asInt(props.get("spacing")));

			case "HStack":
				new cui.ui.HStack(kids, PropValueTools.asInt(props.get("spacing")));

			case "Button":
				new cui.ui.Button(PropValueTools.asString(props.get("label")), action(props.get("onClick")));

			case "Spacer":
				new cui.ui.Spacer();

			case "Box":
				new cui.ui.Box(kids.length > 0 ? kids[0] : null);

			case unknown:
				// Loud rather than invisible: an unmapped type is a bug to see.
				new cui.ui.Text("?" + unknown);
		}
	}

	/** A `PCallback` becomes the handler; anything else becomes a no-op. **/
	static function action(v:Null<PropValue>):Void->Void {
		var r = PropValueTools.resolve(v);
		if (r == null) return function() {};
		return switch (r) {
			case PCallback(fn): fn;
			case _: function() {};
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
	static function colorOf(strings:Array<String>):Null<Color> {
		if (strings == null || strings.length == 0) return null;
		var named:Null<NamedColor> = switch (strings[0].toLowerCase()) {
			case "red": Red;
			case "green": Green;
			case "yellow": Yellow;
			case "blue": Blue;
			case "magenta": Magenta;
			case "cyan": Cyan;
			case "white": White;
			case "black": Black;
			case _: null;
		}
		return named == null ? null : Color.Named(named);
	}
}
