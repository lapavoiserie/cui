package cui.render;

import haxe.io.Bytes;

/**
	A picture in memory: eight bits per channel, red, green, blue, alpha.

	The one shape every way of showing a picture in a terminal starts from --
	half blocks, Sixel, the kitty protocol -- so decoding and drawing never have
	to agree on anything else.
**/
class Pixels {
	public final width:Int;
	public final height:Int;

	/** `width * height * 4` bytes, row by row from the top. **/
	public final rgba:Bytes;

	public function new(width:Int, height:Int, ?rgba:Bytes) {
		this.width = width;
		this.height = height;
		this.rgba = rgba != null ? rgba : Bytes.alloc(width * height * 4);
	}

	public inline function red(x:Int, y:Int):Int
		return rgba.get((y * width + x) * 4);

	public inline function green(x:Int, y:Int):Int
		return rgba.get((y * width + x) * 4 + 1);

	public inline function blue(x:Int, y:Int):Int
		return rgba.get((y * width + x) * 4 + 2);

	public inline function alpha(x:Int, y:Int):Int
		return rgba.get((y * width + x) * 4 + 3);

	public function set(x:Int, y:Int, r:Int, g:Int, b:Int, a:Int = 255):Void {
		var at = (y * width + x) * 4;
		rgba.set(at, r);
		rgba.set(at + 1, g);
		rgba.set(at + 2, b);
		rgba.set(at + 3, a);
	}

	/**
		The same picture at another size, taking the nearest pixel.

		Nearest, not averaged: a terminal shows a picture a few dozen pixels
		across, where an average turns a thin line into nothing at all. This is
		the same choice a terminal's own scaler makes.
	**/
	public function scaled(toWidth:Int, toHeight:Int):Pixels {
		if (toWidth <= 0 || toHeight <= 0 || width <= 0 || height <= 0) return new Pixels(0, 0);
		if (toWidth == width && toHeight == height) return this;
		var out = new Pixels(toWidth, toHeight);
		for (y in 0...toHeight) {
			var from = Std.int(y * height / toHeight);
			for (x in 0...toWidth) {
				var at = ((from * width) + Std.int(x * width / toWidth)) * 4;
				var to = (y * toWidth + x) * 4;
				out.rgba.set(to, rgba.get(at));
				out.rgba.set(to + 1, rgba.get(at + 1));
				out.rgba.set(to + 2, rgba.get(at + 2));
				out.rgba.set(to + 3, rgba.get(at + 3));
			}
		}
		return out;
	}

	/**
		The picture over a background, alpha gone.

		A terminal cell has no transparency: what is behind a picture is the
		panel, and a half-transparent pixel drawn as if it were opaque is how a
		logo with soft edges comes out with a black fringe.
	**/
	public function over(r:Int, g:Int, b:Int):Pixels {
		var out = new Pixels(width, height);
		for (i in 0...width * height) {
			var at = i * 4;
			var a = rgba.get(at + 3);
			out.rgba.set(at, mix(rgba.get(at), r, a));
			out.rgba.set(at + 1, mix(rgba.get(at + 1), g, a));
			out.rgba.set(at + 2, mix(rgba.get(at + 2), b, a));
			out.rgba.set(at + 3, 255);
		}
		return out;
	}

	static inline function mix(over:Int, under:Int, alpha:Int):Int
		return Std.int((over * alpha + under * (255 - alpha)) / 255);
}
