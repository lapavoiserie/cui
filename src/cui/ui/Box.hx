package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

class Box extends View {
    public var child(default, null):View;

    public function new(?child:View) {
        super();
        this.child = child;
        if (child != null) {
            children = [child];
        }
    }

    override public function measure(constraint:Constraint):Size {
        var insets = getInsets();

        if (child == null) {
            var fw = getFixedWidth();
            var fh = getFixedHeight();
            return new Size(
                fw > 0 ? fw : insets.horizontalTotal(),
                fh > 0 ? fh : insets.verticalTotal()
            );
        }

        var innerMaxW = switch (constraint) {
            case Exact(w, _): w - insets.horizontalTotal();
            case AtMost(w, _): w - insets.horizontalTotal();
            case Unbounded: 1000;
        };
        var innerMaxH = switch (constraint) {
            case Exact(_, h): h - insets.verticalTotal();
            case AtMost(_, h): h - insets.verticalTotal();
            case Unbounded: 1000;
        };

        var fw = getFixedWidth();
        if (fw > 0) innerMaxW = fw - insets.horizontalTotal();
        var fh = getFixedHeight();
        if (fh > 0) innerMaxH = fh - insets.verticalTotal();

        var cs = child.measure(Constraint.AtMost(innerMaxW, innerMaxH));

        return new Size(
            fw > 0 ? fw : cs.width + insets.horizontalTotal(),
            fh > 0 ? fh : cs.height + insets.verticalTotal()
        );
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var borderStyle = getBorderStyle();
        var insets = getInsets();

        // Fill background
        switch (style.bg) {
            case Default:
            default:
                buffer.fill(area, " ", style);
        }

        if (borderStyle != cui.render.BorderStyle.None) {
            cui.layout.LayoutEngine.drawBorder(buffer, area, borderStyle, style);
        }

        if (child != null) {
            var inner = area.inner(insets);
            child.render(buffer, inner);
        }
    }
}
