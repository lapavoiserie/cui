package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

/**
	A picture, in a terminal that has none yet.

	nui's canonical `Image` exists here so a tree carrying one is not a hole in
	the panel: what it draws is the `alt`, in brackets, the way a text browser
	shows a picture it cannot fetch. The pixels come with the terminal graphics
	protocols -- Sixel first -- and only the drawing changes when they do; the
	node, its props and this class stay as they are.
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

	override public function measure(constraint:Constraint):Size {
		var insets = getInsets();
		return new Size(display().length + insets.horizontalTotal(), 1 + insets.verticalTotal());
	}

	override public function render(buffer:Buffer, area:Rect):Void {
		frame = area;
		if (isHidden()) return;
		var inner = area.inner(getInsets());
		buffer.writeString(inner.x, inner.y, display(), getEffectiveStyle());
	}
}
