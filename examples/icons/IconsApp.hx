import cui.App;
import cui.View;
import cui.ui.Button;
import cui.ui.HStack;
import cui.ui.Icon;
import cui.ui.Image;
import cui.ui.Text;
import cui.ui.VStack;

/**
	Every icon of the shared vocabulary as a character, pictures standing in as
	their `alt`, and buttons with an icon.

	    haxe build-icons.hxml && ./bin-icons/IconsApp

	The pixels are still to come -- Sixel first, then the other terminal
	graphics protocols -- and only `cui.ui.Image`'s drawing changes when they
	do.
**/
class IconsApp extends App {
	override public function body():View {
		var rows:Array<View> = [new Text("Icons").bold()];
		var names = nui.Icons.NAMES;
		var perRow = 10;
		var i = 0;
		while (i < names.length) {
			var cells:Array<View> = [];
			for (name in names.slice(i, i + perRow)) {
				cells.push(new HStack([new Icon(name), new Text(" " + name)], 0));
			}
			rows.push(new HStack(cells, 1));
			i += perRow;
		}
		rows.push(new Text(""));
		rows.push(new Text("Pictures").bold());
		rows.push(new HStack([
			new Image("asset:logo.png", "Farceur", {width: 120}),
			new Image("refused:a received tree may not name a local file", "refused"),
			new Image("blob:sha256=" + [for (_ in 0...64) "a"].join("")),
		], 2));
		rows.push(new Text(""));
		rows.push(new Text("Buttons").bold());
		rows.push(new HStack([
			new Button("TAKE", () -> {}, "swap"),
			new Button("", () -> {}, "mic-off"),
			new Button("Plain", () -> {}),
		], 2));
		rows.push(new Text("[q] quit").dim());
		return new VStack(rows, 0).padding(1).border(Rounded);
	}

	override public function handleEvent(event:cui.event.Event):Bool {
		switch (event) {
			case Key(key):
				switch (key.code) {
					case Char(c) if (c == "q"): quit(); return true;
					case _:
				}
			case _:
		}
		return false;
	}

	static function main() {
		new IconsApp().run();
	}
}
