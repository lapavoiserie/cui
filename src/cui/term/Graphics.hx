package cui.term;

import cui.render.Kitty;
import cui.render.Pixels;
import cui.render.Sixel;

/** How this terminal can be made to show a picture. **/
enum Protocol {
	/** The kitty graphics protocol: the picture's own bytes, no palette. **/
	KittyGraphics;

	/** Sixel: six rows at a time, from a palette. Windows Terminal has this one. **/
	SixelGraphics;

	/** No protocol: half blocks, which are text and always work. **/
	HalfBlocks;
}

/**
	What this terminal can draw, asked rather than assumed.

	The ladder is kitty, Sixel, half blocks. kitty first because the picture
	crosses as its own pixels; Sixel second because it is what Windows Terminal
	has; half blocks last because they are text and work in anything with
	colour -- including a terminal multiplexer that eats the other two.

	**Asked with a Primary Device Attributes request.** `ESC [ c`, and a
	terminal answers `ESC [ ? 62 ; 4 ; ... c`, where a `4` among the numbers
	means Sixel. The environment says the rest: `TERM` and `KITTY_WINDOW_ID`
	name a terminal that speaks the kitty protocol, and `TERM` beginning with
	`screen` or `tmux` means a multiplexer in the way, which is exactly where
	half blocks earn their place.

	The question is asked once, and only where a reply can be read: a terminal
	in raw mode, with nobody else reading its input. Where that is not so --
	output piped into a file, a test -- the answer is what the environment says
	and, failing that, half blocks.
**/
class Graphics {
	/** What was found, once it has been. **/
	public static var protocol(default, null):Protocol = HalfBlocks;

	/** How many pixels a cell is, for sizing a picture. **/
	public static var cellWidth(default, null):Int = 10;

	public static var cellHeight(default, null):Int = 20;

	static var asked = false;

	/**
		Ask the terminal what it can do.

		`read` is how to read one byte with a timeout in milliseconds, -1 for
		nothing -- `cui.backend.Backend`'s own. Called once, from the backend,
		after raw mode is on.
	**/
	public static function detect(write:String->Void, read:Int->Int):Void {
		if (asked) return;
		asked = true;

		var term = env("TERM");
		var program = env("TERM_PROGRAM");
		// A multiplexer passes neither protocol through unless it is told to,
		// and what it does pass through it may place wrongly. Half blocks are
		// the honest answer there.
		var multiplexed = StringTools.startsWith(term, "screen") || StringTools.startsWith(term, "tmux")
			|| env("TMUX") != "" || env("STY") != "";
		if (multiplexed) {
			protocol = HalfBlocks;
			return;
		}

		if (term.indexOf("kitty") >= 0 || term.indexOf("ghostty") >= 0 || env("KITTY_WINDOW_ID") != ""
			|| program == "WezTerm" || program == "ghostty") {
			protocol = KittyGraphics;
			return;
		}

		// Windows Terminal says so in the environment and answers the request
		// as well; asking covers every other terminal that has Sixel.
		if (env("WT_SESSION") != "") {
			protocol = SixelGraphics;
			return;
		}

		var reply = ask(write, read, "\x1b[c", 200);
		if (reply.indexOf(";4;") >= 0 || StringTools.endsWith(reply, ";4c") || reply.indexOf("?4;") >= 0)
			protocol = SixelGraphics;

		// How big a cell is, in pixels: `ESC [ 14 t` answers the window's size
		// and `ESC [ 18 t` its size in cells. Together they are the cell, and
		// without them the defaults above are a common terminal's.
		var pixels = numbers(ask(write, read, "\x1b[14t", 200));
		var grid = numbers(ask(write, read, "\x1b[18t", 200));
		if (pixels.length >= 3 && grid.length >= 3 && grid[1] > 0 && grid[2] > 0) {
			var w = Std.int(pixels[2] / grid[2]);
			var h = Std.int(pixels[1] / grid[1]);
			if (w > 0) cellWidth = w;
			if (h > 0) cellHeight = h;
		}
	}

	/** What a test, or an application that knows better, may say instead. **/
	public static function say(what:Protocol, ?cellPixelWidth:Int, ?cellPixelHeight:Int):Void {
		asked = true;
		protocol = what;
		if (cellPixelWidth != null && cellPixelWidth > 0) cellWidth = cellPixelWidth;
		if (cellPixelHeight != null && cellPixelHeight > 0) cellHeight = cellPixelHeight;
	}

	/**
		The escape sequence that draws `pixels` in a box of cells, or `null`
		when this terminal has no protocol and the cells must be drawn instead.
	**/
	public static function sequence(pixels:Pixels, columns:Int, rows:Int):Null<String> {
		return switch (protocol) {
			case KittyGraphics: Kitty.encode(pixels, columns, rows);
			case SixelGraphics: Sixel.encode(pixels.scaled(columns * cellWidth, rows * cellHeight));
			case HalfBlocks: null;
		}
	}

	static function ask(write:String->Void, read:Int->Int, question:String, timeoutMs:Int):String {
		write(question);
		var out = new StringBuf();
		// A reply ends at the letter that closes it; nothing else is expected
		// on the wire while the application has not drawn anything yet.
		while (true) {
			var byte = read(timeoutMs);
			if (byte < 0) break;
			out.addChar(byte);
			if ((byte >= 0x40 && byte <= 0x5A && byte != 0x5B) || (byte >= 0x61 && byte <= 0x7A)) break;
			if (out.length > 64) break;
		}
		return out.toString();
	}

	static function numbers(reply:String):Array<Int> {
		var out = [];
		var digits = "";
		for (i in 0...reply.length) {
			var c = reply.charAt(i);
			if (c >= "0" && c <= "9") {
				digits += c;
			} else if (digits != "") {
				out.push(Std.parseInt(digits));
				digits = "";
			}
		}
		if (digits != "") out.push(Std.parseInt(digits));
		return out;
	}

	static function env(name:String):String {
		#if sys
		var v = Sys.getEnv(name);
		return v == null ? "" : v;
		#else
		return "";
		#end
	}
}
