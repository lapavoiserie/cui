import cui.App;
import cui.View;
import cui.event.Event;
import cui.nui.NodeRenderer;
import cui.nui.ViewSource;
import cui.ui.Text;
import cui.ui.VStack;
import nui.Node;
import nui.PropValue;

/**
	Displays a tree that cui did not build.

	Everything below the header is described as a **`nui.Node` tree** — the shared
	node model — and handed to `NodeRenderer`, which turns it into cui views. The
	terminal then draws it like anything else.

	The point: a tree described by another backend, sent over a protocol or
	produced by a devtool can be displayed here without cui knowing anything
	about where it came from.

	The last section closes the loop: the rendered tree is read back through
	`ViewSource` — the pull contract — and its own description is printed.

	    haxe build-nui-tree.hxml && ./bin-nui-tree/NuiTreeApp
**/
class NuiTreeApp extends App {
	@:state var presses:Int = 0;

	/** The foreign tree. Nothing here is a cui type. **/
	function foreignTree():Node {
		var header = new Node("Text").prop("text", PString("-- décrit en nui, rendu par cui --"));

		var row = new Node("HStack")
			.prop("spacing", PInt(2))
			.child(new Node("Text").prop("text", PString("Statut :")))
			.child(new Node("Text").prop("text", PString("vivant")));
		row.modifiers.push({type: "foregroundColor", strings: ["green"]});

		var boxed = new Node("Box").child(new Node("Text").prop("text", PString("dans une boîte")));
		boxed.modifiers.push({type: "border"});

		var button = new Node("Button")
			.prop("label", PString("Appuyez sur Entrée"))
			.prop("onClick", PCallback(function() presses.set(presses.get() + 1)));

		var unknown = new Node("Hologramme");

		var tree = new Node("VStack")
			.prop("spacing", PInt(1))
			.child(header)
			.child(row)
			.child(boxed)
			.child(button)
			.child(new Node("Text").prop("text", PString("type inconnu ci-dessous :")))
			.child(unknown);

		tree.modifiers.push({type: "padding", floats: [1]});
		return tree;
	}

	override public function body():View {
		var tree = foreignTree();
		var rendered = NodeRenderer.build(tree);

		// Le contrat pull, en sens inverse : relire ce qu'on vient de rendre.
		var src = new ViewSource(rendered);
		var described = src.typeOf(src.root()) + " · " + src.childCount(src.root()) + " enfants · "
			+ src.modifierCount(src.root()) + " modificateur(s)";

		return new VStack([
			new Text("cui affiche un arbre nui").bold(),
			rendered,
			new Text("relu par ViewSource : " + described),
			new Text("appuis : " + presses.get() + "   ·   q pour quitter")
		], 1);
	}

	override public function handleEvent(event:Event):Bool {
		switch (event) {
			case Key(key):
				switch (key.code) {
					case Char(c):
						if (c == "q") {
							quit();
							return true;
						}
					default:
				}
			default:
		}
		// Not handled here: let it reach the focused view, so Tab and Enter
		// still drive the button.
		return super.handleEvent(event);
	}

	static function main() {
		new NuiTreeApp().run();
	}
}
