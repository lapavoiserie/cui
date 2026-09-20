package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

/**
	Children in the same place, drawn in the order they are written.

	The canon's overlay. On a terminal it is the cheapest of the three stacks
	and the most surprising: a cell holds one character, so the LAST child to
	write one wins, and a child that draws nothing where another drew something
	leaves what was there. There is no alpha to blend, so "over" means
	"afterwards".

	Sized by its widest and tallest child, not by the space it is offered --
	which is what `Spacer` is for, and what a `width`/`height` modifier is for
	when an overlay must be bigger than what it holds.
**/
@:node("ZStack")
@:content("children")
class ZStack extends View {
	public function new(children:Array<View>) {
		super();
		this.children = children;
	}

	override public function measure(constraint:Constraint):Size {
		var insets = getInsets();

		var maxW = switch (constraint) {
			case Exact(w, _): w - insets.horizontalTotal();
			case AtMost(w, _): w - insets.horizontalTotal();
			case Unbounded: 1000;
		};
		var maxH = switch (constraint) {
			case Exact(_, h): h - insets.verticalTotal();
			case AtMost(_, h): h - insets.verticalTotal();
			case Unbounded: 1000;
		};

		var fw = getFixedWidth();
		if (fw > 0) maxW = fw - insets.horizontalTotal();
		var fh = getFixedHeight();
		if (fh > 0) maxH = fh - insets.verticalTotal();

		var widest = 0;
		var tallest = 0;
		for (child in children) {
			var cs = child.measure(Constraint.AtMost(maxW, maxH));
			if (cs.width > widest) widest = cs.width;
			if (cs.height > tallest) tallest = cs.height;
		}

		return new Size(
			fw > 0 ? fw : widest + insets.horizontalTotal(),
			fh > 0 ? fh : tallest + insets.verticalTotal()
		);
	}

	override public function render(buffer:Buffer, area:Rect):Void {
		if (isHidden()) return;

		var style = getEffectiveStyle();
		var borderStyle = getBorderStyle();
		var insets = getInsets();

		switch (style.bg) {
			case Default:
			default:
				buffer.fill(area, " ", style);
		}

		if (borderStyle != cui.render.BorderStyle.None) {
			cui.layout.LayoutEngine.drawBorder(buffer, area, borderStyle, style);
		}

		// Every child into the SAME rectangle, in order. The last one to write
		// a cell is the one that is seen.
		var inner = area.inner(insets);
		for (child in children) child.renderInto(buffer, inner);
	}
}
