package cui.render;

/**
	Pixels as Sixel: the one picture protocol Windows Terminal speaks.

	A Sixel band is six rows of pixels at a time, one character per column per
	colour: the six bits of `63 + bits` say which of the six rows that column
	paints. A band is written once per colour it uses, with `$` returning to the
	start of the band and `-` moving to the next.

	**A palette taken from the picture.** Sixel allows 256 colour registers, and
	a picture with no more colours than that crosses exactly as it is. Above
	that the colours are cut into 256 boxes by their widest channel -- median
	cut -- and each box becomes the average of what fell in it. A fixed cube of
	216 was what this did first, and the Farceur session's switcher showed why
	it was not enough: a gradient came out in visible steps.
**/
class Sixel {
	/** How many colour registers a Sixel picture may use. **/
	public static inline var REGISTERS = 256;

	/** The colours a picture is drawn with, and which register each pixel takes. **/
	public static function palette(pixels:Pixels):{colours:Array<Int>, of:Int->Int} {
		var counts = new Map<Int, Int>();
		for (i in 0...pixels.width * pixels.height) {
			var at = i * 4;
			var rgb = (pixels.rgba.get(at) << 16) | (pixels.rgba.get(at + 1) << 8) | pixels.rgba.get(at + 2);
			counts.set(rgb, (counts.exists(rgb) ? counts.get(rgb) : 0) + 1);
		}
		var distinct = [for (c in counts.keys()) c];

		// Few enough colours to name them all: nothing is lost, which is the
		// ordinary case for a panel, an icon or a screenshot of text.
		if (distinct.length <= REGISTERS) {
			distinct.sort(Reflect.compare);
			var index = new Map<Int, Int>();
			for (i in 0...distinct.length) index.set(distinct[i], i);
			return {colours: distinct, of: rgb -> index.exists(rgb) ? index.get(rgb) : 0};
		}

		var boxes = cut(distinct, counts);
		var colours = [for (box in boxes) average(box, counts)];
		// Nearest colour, remembered: a photograph asks the same question tens
		// of thousands of times, and the answer depends only on the colour.
		var known = new Map<Int, Int>();
		return {
			colours: colours,
			of: rgb -> {
				if (known.exists(rgb)) return known.get(rgb);
				var best = 0;
				var closest = -1;
				for (i in 0...colours.length) {
					var d = distance(rgb, colours[i]);
					if (closest < 0 || d < closest) {
						closest = d;
						best = i;
					}
				}
				known.set(rgb, best);
				best;
			}
		};
	}

	/** Median cut: split the widest channel of the widest box, until there are enough. **/
	static function cut(distinct:Array<Int>, counts:Map<Int, Int>):Array<Array<Int>> {
		var boxes = [distinct];
		while (boxes.length < REGISTERS) {
			var widest = -1;
			var spread = 0;
			var channel = 0;
			for (i in 0...boxes.length) {
				if (boxes[i].length < 2) continue;
				var range = extent(boxes[i]);
				for (c in 0...3) {
					if (range[c] > spread) {
						spread = range[c];
						widest = i;
						channel = c;
					}
				}
			}
			if (widest < 0 || spread == 0) break;
			var box = boxes[widest];
			var shift = (2 - channel) * 8;
			box.sort((a, b) -> ((a >> shift) & 0xFF) - ((b >> shift) & 0xFF));
			// Split where half the pixels are, not half the colours: a colour
			// two pixels use must not claim a register of its own while a
			// gradient shares one.
			var half = Std.int(weight(box, counts) / 2);
			var running = 0;
			var at = 0;
			while (at < box.length - 1 && running < half) {
				running += counts.get(box[at]);
				at++;
			}
			boxes[widest] = box.slice(0, at);
			boxes.push(box.slice(at));
		}
		return boxes;
	}

	static function extent(box:Array<Int>):Array<Int> {
		var low = [255, 255, 255];
		var high = [0, 0, 0];
		for (rgb in box) {
			for (c in 0...3) {
				var v = (rgb >> ((2 - c) * 8)) & 0xFF;
				if (v < low[c]) low[c] = v;
				if (v > high[c]) high[c] = v;
			}
		}
		return [high[0] - low[0], high[1] - low[1], high[2] - low[2]];
	}

	static function weight(box:Array<Int>, counts:Map<Int, Int>):Int {
		var total = 0;
		for (rgb in box) total += counts.get(rgb);
		return total;
	}

	static function average(box:Array<Int>, counts:Map<Int, Int>):Int {
		var r = 0.0;
		var g = 0.0;
		var b = 0.0;
		var total = 0;
		for (rgb in box) {
			var n = counts.get(rgb);
			r += ((rgb >> 16) & 0xFF) * n;
			g += ((rgb >> 8) & 0xFF) * n;
			b += (rgb & 0xFF) * n;
			total += n;
		}
		if (total == 0) return 0;
		return (Math.round(r / total) << 16) | (Math.round(g / total) << 8) | Math.round(b / total);
	}

	static inline function distance(a:Int, b:Int):Int {
		var dr = ((a >> 16) & 0xFF) - ((b >> 16) & 0xFF);
		var dg = ((a >> 8) & 0xFF) - ((b >> 8) & 0xFF);
		var db = (a & 0xFF) - (b & 0xFF);
		return dr * dr + dg * dg + db * db;
	}

	/** The whole sequence, ready to write where the cursor stands. **/
	public static function encode(pixels:Pixels):String {
		if (pixels.width <= 0 || pixels.height <= 0) return "";
		var chosen = palette(pixels);
		var out = new StringBuf();
		// P1 = 0 (pixel aspect 1:1), P2 = 1 (a pixel of no colour stays as it
		// was, rather than being painted the background), P3 = 0.
		out.add("\x1bP0;1;0q");
		// The picture's size, so a terminal that honours it reserves the room.
		out.add('"1;1;${pixels.width};${pixels.height}');

		for (i in 0...chosen.colours.length) {
			var rgb = chosen.colours[i];
			// Sixel colours are percentages, not bytes.
			out.add('#$i;2;${percent((rgb >> 16) & 0xFF)};${percent((rgb >> 8) & 0xFF)};${percent(rgb & 0xFF)}');
		}

		// Which register each pixel takes, worked out once: the bands below ask
		// about every pixel once per colour in the band.
		var indices = haxe.io.Bytes.alloc(pixels.width * pixels.height);
		for (i in 0...pixels.width * pixels.height) {
			var at = i * 4;
			indices.set(i, chosen.of((pixels.rgba.get(at) << 16) | (pixels.rgba.get(at + 1) << 8) | pixels.rgba.get(at + 2)));
		}

		var y = 0;
		while (y < pixels.height) {
			var rows = pixels.height - y;
			if (rows > 6) rows = 6;

			// Only the colours this band actually uses, in the order they
			// appear: a picture of 256 colours would otherwise write 256 empty
			// runs per band.
			var here = [];
			var seen = new Map<Int, Bool>();
			for (row in 0...rows)
				for (x in 0...pixels.width) {
					var c = indices.get((y + row) * pixels.width + x);
					if (!seen.exists(c)) {
						seen.set(c, true);
						here.push(c);
					}
				}

			var first = true;
			for (c in here) {
				var band = new StringBuf();
				var run = 0;
				var runChar = -1;
				for (x in 0...pixels.width) {
					var bits = 0;
					for (row in 0...rows)
						if (indices.get((y + row) * pixels.width + x) == c)
							bits |= 1 << row;
					var ch = 63 + bits;
					if (ch == runChar) {
						run++;
					} else {
						if (runChar >= 0) addRun(band, runChar, run);
						runChar = ch;
						run = 1;
					}
				}
				if (runChar >= 0) addRun(band, runChar, run);
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
