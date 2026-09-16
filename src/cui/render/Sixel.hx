package cui.render;

/**
	Pixels as Sixel: the one picture protocol Windows Terminal speaks.

	A Sixel band is six rows of pixels at a time, one character per column per
	colour: the six bits of `63 + bits` say which of the six rows that column
	paints. A band is written once per colour it uses, with `$` returning to the
	start of the band and `-` moving to the next.

	**A fixed palette of 216.** Six levels of red, green and blue -- the same
	cube a terminal's own 256-colour palette uses for its middle range. A
	picture of a panel is flat colour and text; the cube costs nothing to build,
	needs no second pass over the pixels, and cannot make the two ends disagree
	about what a colour index means.
**/
class Sixel {
	/** How many levels each channel is quantised to. **/
	public static inline var LEVELS = 6;

	/** The index of a colour in the cube. **/
	public static inline function index(r:Int, g:Int, b:Int):Int
		return level(r) * LEVELS * LEVELS + level(g) * LEVELS + level(b);

	static inline function level(v:Int):Int {
		var l = Std.int((v * LEVELS) / 256);
		return l >= LEVELS ? LEVELS - 1 : (l < 0 ? 0 : l);
	}

	/** A level back to a channel value: the middle of what it stands for. **/
	public static inline function value(l:Int):Int
		return Std.int(l * 255 / (LEVELS - 1));

	/** The whole sequence, ready to write where the cursor stands. **/
	public static function encode(pixels:Pixels):String {
		if (pixels.width <= 0 || pixels.height <= 0) return "";
		var out = new StringBuf();
		// P1 = 0 (pixel aspect 1:1), P2 = 1 (a pixel of no colour stays as it
		// was, rather than being painted the background), P3 = 0.
		out.add("\x1bP0;1;0q");
		// The picture's size, so a terminal that honours it reserves the room.
		out.add('"1;1;${pixels.width};${pixels.height}');

		var used = new Map<Int, Bool>();
		for (i in 0...pixels.width * pixels.height) {
			var at = i * 4;
			used.set(index(pixels.rgba.get(at), pixels.rgba.get(at + 1), pixels.rgba.get(at + 2)), true);
		}
		var colours = [for (c in used.keys()) c];
		colours.sort(Reflect.compare);
		for (c in colours) {
			var r = Std.int(c / (LEVELS * LEVELS));
			var g = Std.int(c / LEVELS) % LEVELS;
			var b = c % LEVELS;
			// Sixel colours are percentages, not bytes.
			out.add('#$c;2;${percent(value(r))};${percent(value(g))};${percent(value(b))}');
		}

		var y = 0;
		while (y < pixels.height) {
			var rows = pixels.height - y;
			if (rows > 6) rows = 6;
			var first = true;
			for (c in colours) {
				var band = new StringBuf();
				var run = 0;
				var runChar = -1;
				var painted = false;
				for (x in 0...pixels.width) {
					var bits = 0;
					for (row in 0...rows) {
						var at = ((y + row) * pixels.width + x) * 4;
						if (index(pixels.rgba.get(at), pixels.rgba.get(at + 1), pixels.rgba.get(at + 2)) == c)
							bits |= 1 << row;
					}
					if (bits != 0) painted = true;
					var ch = 63 + bits;
					if (ch == runChar) {
						run++;
					} else {
						if (runChar >= 0) addRun(band, runChar, run);
						runChar = ch;
						run = 1;
					}
				}
				if (runChar >= 0 && painted) addRun(band, runChar, run);
				if (!painted) continue;
				if (!first) out.add("$");
				out.add("#" + c);
				out.add(band.toString());
				first = false;
			}
			out.add("-");
			y += 6;
		}
		out.add("\x1b\\");
		return out.toString();
	}

	/** Runs of four or more are worth their `!n` header; shorter ones are not. **/
	static function addRun(band:StringBuf, ch:Int, run:Int):Void {
		if (run >= 4) {
			band.add("!" + run);
			band.addChar(ch);
			return;
		}
		for (_ in 0...run) band.addChar(ch);
	}

	static inline function percent(v:Int):Int
		return Math.round(v * 100 / 255);
}
