package cui.render;

import cui.layout.Rect;

/**
	Pixels as characters, for a terminal that draws no pictures at all.

	A cell holds an upper half block: what is above the line is the
	character's own colour, what is below it the cell's background. So a cell
	is two pixels tall and one wide, and a picture needs no protocol, no
	permission and no reply -- it is text, in a terminal that has colour.

	This is the floor of the ladder (`cui.term.Graphics`): whatever a terminal
	turns out not to support, this works, and only a terminal with no colour at
	all falls through to the `alt`.
**/
class Blocks {
	/** The upper half block: the character every cell of a picture holds. **/
	public static inline var HALF = "▀";

	/** How many pixels fit in a cell this way. **/
	public static inline var PIXELS_WIDE = 1;

	public static inline var PIXELS_TALL = 2;

	/** Draw `pixels` into `area`, two pixel rows per cell. **/
	public static function draw(buffer:Buffer, area:Rect, pixels:Pixels):Void {
		var scaled = pixels.scaled(area.width, area.height * PIXELS_TALL);
		for (row in 0...area.height) {
			for (column in 0...area.width) {
				var top = row * 2;
				var bottom = top + 1;
				var style = new Style();
				style.fg = colourAt(scaled, column, top);
				style.bg = colourAt(scaled, column, bottom < scaled.height ? bottom : top);
				buffer.set(area.x + column, area.y + row, HALF, style);
			}
		}
	}

	static function colourAt(pixels:Pixels, x:Int, y:Int):Color {
		if (x >= pixels.width || y >= pixels.height) return Color.Default;
		return Color.Rgb(pixels.red(x, y), pixels.green(x, y), pixels.blue(x, y));
	}
}
