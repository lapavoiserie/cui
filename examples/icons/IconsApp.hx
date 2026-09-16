import cui.App;
import cui.View;
import cui.ui.Button;
import cui.ui.HStack;
import cui.ui.Icon;
import cui.ui.Image;
import cui.ui.Text;
import cui.ui.VStack;

/**
	Every icon of the shared vocabulary as a character, a picture drawn with
	whatever this terminal can do, and buttons with an icon.

	    haxe build-icons.hxml
	    cd examples/icons && ../../bin-icons/IconsApp

	**From this directory**, because that is where the `assets` are: an
	`asset:` source is looked up beside the executable and beside where the
	application was started, and cui has no build step to copy a directory
	with. Run from anywhere else and the picture shows its `alt`, which is the
	right answer to "there is no such file here" and a puzzling one to meet by
	accident.

	The picture is the same in kitty, in Windows Terminal and in a multiplexer:
	`cui.term.Graphics` asks the terminal what it has -- the kitty protocol,
	Sixel, or half blocks, which are text -- and what has no pixels at all shows
	its `alt`.
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
			new Image("asset:test.png", "a picture this application ships", {width: 120, height: 80}),
			new Image("asset:not-shipped.png", "missing asset"),
			new Image("refused:a received tree may not name a local file", "refused"),
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
