package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

/**
	An icon of the shared vocabulary, as one character (`cui.nui.Icons`).

	A name this terminal has no character for -- a tree from a newer sender --
	is its label, as text, which is the same answer every other backend gives.
**/
class Icon extends View {
	public var name(default, null):String;
	public var label(default, null):Null<String>;

	public function new(name:String, ?label:String) {
		super();
		this.name = name;
		this.label = label;
	}

	/** What this draws: the character, else the words. **/
	public function display():String {
		var glyph = cui.nui.Icons.glyphOf(name);
		if (glyph != null) return glyph;
		return label != null && label != "" ? label : nui.Icons.spoken(name);
	}

	override public function measure(constraint:Constraint):Size {
		var insets = getInsets();
		// Cells, not code points: a stroked name is two code points in one
		// cell, and a character drawn as a picture asks for two (`Icons.ROOM`).
		var glyph = cui.nui.Icons.glyphOf(name);
		var w = glyph != null ? cui.nui.Icons.cellsOf(name) : display().length;
		return new Size(w + insets.horizontalTotal(), 1 + insets.verticalTotal());
	}

	override public function render(buffer:Buffer, area:Rect):Void {
		frame = area;
		if (isHidden()) return;
		var inner = area.inner(getInsets());
		var glyph = cui.nui.Icons.glyphOf(name);
		var style = getEffectiveStyle();
		if (glyph == null) {
			buffer.writeString(inner.x, inner.y, display(), style);
			return;
		}
		switch (cui.nui.Icons.roomOf(name)) {
			case Wide:
				buffer.setWide(inner.x, inner.y, glyph, style);
			case Inked:
				buffer.writeString(inner.x, inner.y, glyph, style);
				// The blank the picture is drawn over. Written rather than
				// merely reserved, so that what was there before is cleared.
				buffer.set(inner.x + 1, inner.y, " ", style);
			case One:
				buffer.writeString(inner.x, inner.y, glyph, style);
		}
	}
}
