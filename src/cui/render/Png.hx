package cui.render;

import haxe.io.Bytes;
import haxe.io.BytesInput;

/**
	PNG, decoded here.

	A terminal draws pictures by putting pixels on the screen itself -- Sixel,
	the kitty protocol, half blocks -- so `cui` is the one backend that needs
	the pixels rather than a handle to hand a platform. Written rather than
	taken from a library so that a terminal application stays one library and a
	compiler.

	Eight bits per channel, greyscale, palette, RGB and RGBA, with or without an
	alpha channel, non-interlaced -- what a screenshot, a logo or a thumbnail
	is. Sixteen bits per channel and Adam7 interlacing are refused with a word
	rather than half-decoded: the picture then shows its `alt`.
**/
class Png {
	/** The pixels of a PNG, or `null` when this is not one this can read. **/
	public static function decode(bytes:Bytes):Null<Pixels> {
		return try read(bytes) catch (_:Dynamic) null;
	}

	/** Why the last decode gave up, for a test that wants to know. **/
	public static var refusal:String = "";

	static function no(reason:String):Null<Pixels> {
		refusal = reason;
		return null;
	}

	static function read(bytes:Bytes):Null<Pixels> {
		if (bytes == null || bytes.length < 8) return no("too short");
		for (i => expected in [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
			if (bytes.get(i) != expected) return no("not a PNG");

		var input = new BytesInput(bytes, 8);
		input.bigEndian = true;

		var width = 0;
		var height = 0;
		var depth = 0;
		var colour = 0;
		var interlace = 0;
		var palette:Null<Bytes> = null;
		var alphas:Null<Bytes> = null;
		var data = new haxe.io.BytesBuffer();

		while (input.position < bytes.length - 8) {
			var length = input.readInt32();
			var kind = input.readString(4);
			if (length < 0 || input.position + length > bytes.length) return no("a chunk runs past the end");
			switch (kind) {
				case "IHDR":
					width = input.readInt32();
					height = input.readInt32();
					depth = input.readByte();
					colour = input.readByte();
					input.readByte(); // compression: deflate, the only one there is
					input.readByte(); // filter: the five of the specification
					interlace = input.readByte();
				case "PLTE":
					palette = input.read(length);
				case "tRNS":
					alphas = input.read(length);
				case "IDAT":
					data.add(input.read(length));
				case "IEND":
					break;
				case _:
					input.read(length);
			}
			input.readInt32(); // the chunk's CRC: the file is in memory already
		}

		if (width <= 0 || height <= 0 || depth != 8 || interlace != 0) return no("only eight bits a channel, not interlaced: " + width + "x" + height + " depth " + depth + " interlace " + interlace);
		var channels = switch (colour) {
			case 0: 1; // grey
			case 2: 3; // rgb
			case 3: 1; // palette index
			case 4: 2; // grey and alpha
			case 6: 4; // rgba
			case _: return no("colour type " + colour);
		}
		if (colour == 3 && palette == null) return no("a palette picture with no palette");

		var raw = uncompress(data.getBytes());
		if (raw == null) return no("the pixel data did not inflate");

		var stride = width * channels;
		if (raw.length < (stride + 1) * height) return no("short of pixels: " + raw.length + " for " + ((stride + 1) * height));

		var out = new Pixels(width, height);
		var line = Bytes.alloc(stride);
		var previous = Bytes.alloc(stride);
		var at = 0;
		for (y in 0...height) {
			var filter = raw.get(at++);
			line.blit(0, raw, at, stride);
			at += stride;
			unfilter(filter, line, previous, channels);
			for (x in 0...width) {
				var i = x * channels;
				switch (colour) {
					case 0:
						var v = line.get(i);
						out.set(x, y, v, v, v, 255);
					case 2:
						out.set(x, y, line.get(i), line.get(i + 1), line.get(i + 2), 255);
					case 3:
						var index = line.get(i);
						var p = palette;
						if (p == null || index * 3 + 2 >= p.length) return no("a palette index outside the palette");
						var a = alphas != null && index < alphas.length ? alphas.get(index) : 255;
						out.set(x, y, p.get(index * 3), p.get(index * 3 + 1), p.get(index * 3 + 2), a);
					case 4:
						var v = line.get(i);
						out.set(x, y, v, v, v, line.get(i + 1));
					case 6:
						out.set(x, y, line.get(i), line.get(i + 1), line.get(i + 2), line.get(i + 3));
				}
			}
			previous.blit(0, line, 0, stride);
		}
		return out;
	}

	static function uncompress(deflated:Bytes):Null<Bytes> {
		if (deflated.length == 0) return null;
		// `InflateImpl` reads the zlib header itself -- handed the data two
		// bytes in, as the wrapper's own length suggests, it says "Invalid
		// data". It is the pure-Haxe one deliberately: `haxe.zip.Uncompress`
		// is a binding to the system's zlib, which not every target has.
		return try haxe.zip.InflateImpl.run(new BytesInput(deflated)) catch (_:Dynamic) null;
	}

	/**
		Undo one scanline's filter, in place.

		The five of the specification. Each works on the byte `channels` back in
		the same line and the byte above it -- which is why the decoder keeps
		the previous line rather than the whole picture.
	**/
	static function unfilter(filter:Int, line:Bytes, previous:Bytes, channels:Int):Void {
		var length = line.length;
		switch (filter) {
			case 0:
			case 1:
				for (i in channels...length)
					line.set(i, (line.get(i) + line.get(i - channels)) & 0xFF);
			case 2:
				for (i in 0...length)
					line.set(i, (line.get(i) + previous.get(i)) & 0xFF);
			case 3:
				for (i in 0...length) {
					var left = i >= channels ? line.get(i - channels) : 0;
					line.set(i, (line.get(i) + Std.int((left + previous.get(i)) / 2)) & 0xFF);
				}
			case 4:
				for (i in 0...length) {
					var left = i >= channels ? line.get(i - channels) : 0;
					var up = previous.get(i);
					var upLeft = i >= channels ? previous.get(i - channels) : 0;
					line.set(i, (line.get(i) + paeth(left, up, upLeft)) & 0xFF);
				}
			case _:
		}
	}

	static function paeth(a:Int, b:Int, c:Int):Int {
		var p = a + b - c;
		var pa = p > a ? p - a : a - p;
		var pb = p > b ? p - b : b - p;
		var pc = p > c ? p - c : c - p;
		if (pa <= pb && pa <= pc) return a;
		return pb <= pc ? b : c;
	}
}
