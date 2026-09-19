package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

class ForEach<T> extends View {
    var items:Array<T>;
    var builder:T->View;
    var spacing:Int;

    public function new(items:Array<T>, builder:T->View, spacing:Int = 0) {
        super();
        this.items = items;
        this.builder = builder;
        this.spacing = spacing;
        // Build children so focus ring can find focusable descendants
        children = [for (item in items) builder(item)];
    }

    override public function measure(constraint:Constraint):Size {
        var insets = getInsets();
        var maxW = switch (constraint) {
            case Exact(w, _): w - insets.horizontalTotal();
            case AtMost(w, _): w - insets.horizontalTotal();
            case Unbounded: 40;
        };

        var totalH = 0;
        var widest = 0;
        for (child in children) {
            var cs = child.measure(Constraint.AtMost(maxW, 1000));
            totalH += cs.height;
            if (cs.width > widest) widest = cs.width;
        }
        if (children.length > 1) totalH += spacing * (children.length - 1);

        var fw = getFixedWidth();
        var fh = getFixedHeight();
        return new Size(
            fw > 0 ? fw : widest + insets.horizontalTotal(),
            fh > 0 ? fh : totalH + insets.verticalTotal()
        );
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var borderStyle = getBorderStyle();
        var insets = getInsets();

        if (borderStyle != cui.render.BorderStyle.None) {
            cui.layout.LayoutEngine.drawBorder(buffer, area, borderStyle, style);
        }

        var inner = area.inner(insets);
        var yOffset = inner.y;

        for (child in children) {
            if (yOffset >= inner.y + inner.height) break;

            var cs = child.measure(Constraint.AtMost(inner.width, inner.height));
            var h = cs.height;
            if (yOffset + h > inner.y + inner.height) {
                h = inner.y + inner.height - yOffset;
            }
            if (h <= 0) { yOffset += spacing; continue; }

            child.renderInto(buffer, new Rect(inner.x, yOffset, inner.width, h));
            yOffset += h + spacing;
        }
    }
}
