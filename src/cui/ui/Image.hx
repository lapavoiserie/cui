package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

/**
	A picture, drawn with whatever this terminal can do.

	`cui.term.Graphics` says which that is: the kitty protocol, Sixel, or half
	blocks -- text, which works in anything with colour, including through a
	multiplexer. What has no pixels at all, because the source names nothing
	this can read or the terminal has no colour, draws the `alt` in brackets,
	the way a text browser shows a picture it cannot fetch.

	**Sized in cells.** `width` and `height` are points, as on every other
	backend; a terminal turns them into cells with the size a cell actually has
	(asked of the terminal, or a common one's). With neither, the picture takes
	the room its own pixels ask for, within reason.
**/
class Image extends View {
	public var src(default, null):String;
	public var alt(default, null):String;
	/** The size a graphical backend would draw it at; a terminal keeps it for
		the day it can (`width` and `height` are taken on cui's own View). **/
	public var drawWidth(default, null):Null<Float>;
	public var drawHeight(default, null):Null<Float>;
	public var fit(default, null):String;

	public function new(src:String, ?alt:String, ?options:{?width:Float, ?height:Float, ?fit:String}) {
		super();
		this.src = src == null ? "" : src;
		this.alt = alt == null ? "" : alt;
		this.drawWidth = options != null && options.width != null ? options.width : null;
		this.drawHeight = options != null && options.height != null ? options.height : null;
		this.fit = options != null && options.fit != null ? options.fit : "contain";
	}

	/** The words that stand in for the picture. **/
	public function display():String
		return "[" + (alt == "" ? "picture" : alt) + "]";

	/** The pixels, decoded once, or null when there are none to draw. **/
	public function pixels():Null<cui.render.Pixels>
		return cui.render.Picture.of(src);

	/**
		How many cells the picture takes.

		The size it was given, in points, over the size of a cell; else the
		picture's own pixels, capped so a photograph does not take a screen.
	**/
	public function cells():{columns:Int, rows:Int} {
		var px = pixels();
		if (px == null) return {columns: 0, rows: 0};
		var cellW = cui.term.Graphics.cellWidth;
		var cellH = cui.term.Graphics.cellHeight;
		var wide = drawWidth != null ? drawWidth : (drawHeight != null ? drawHeight * px.width / px.height : px.width);
		var tall = drawHeight != null ? drawHeight : (drawWidth != null ? drawWidth * px.height / px.width : px.height);
		var columns = Math.ceil(wide / cellW);
		var rows = Math.ceil(tall / cellH);
		if (columns < 1) columns = 1;
		if (rows < 1) rows = 1;
		if (columns > 120) columns = 120;
		if (rows > 40) rows = 40;
		return {columns: columns, rows: rows};
	}

	override public function measure(constraint:Constraint):Size {
		var insets = getInsets();
		var box = cells();
		if (box.columns == 0)
			return new Size(display().length + insets.horizontalTotal(), 1 + insets.verticalTotal());
		return new Size(box.columns + insets.horizontalTotal(), box.rows + insets.verticalTotal());
	}

	override public function render(buffer:Buffer, area:Rect):Void {
		frame = area;
		if (isHidden()) return;
		var inner = area.inner(getInsets());
		var px = pixels();
		var box = cells();
		if (px == null || box.columns == 0) {
			buffer.writeString(inner.x, inner.y, display(), getEffectiveStyle());
			return;
		}
		var columns = box.columns < inner.width ? box.columns : inner.width;
		var rows = box.rows < inner.height ? box.rows : inner.height;
		if (columns <= 0 || rows <= 0) return;

		var sequence = cui.term.Graphics.sequence(px, columns, rows);
		if (sequence == null) {
			cui.render.Blocks.draw(buffer, new Rect(inner.x, inner.y, columns, rows), px);
			return;
		}
		// The cells the picture covers are cleared: what the terminal draws
		// there is pixels, and a character underneath would show through the
		// parts of it that are not painted.
		var blank = getEffectiveStyle();
		for (row in 0...rows)
			for (column in 0...columns)
				buffer.set(inner.x + column, inner.y + row, " ", blank);
		buffer.graphic(inner.x, inner.y, sequence);
	}
}
