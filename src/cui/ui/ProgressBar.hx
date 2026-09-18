package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;
import cui.render.Style;
import cui.render.Color;

@:node("ProgressView")
class ProgressBar extends View {
    @:prop var value:Float; // 0.0 to 1.0
    @:prop var label:String;

    public function new(value:Float, label:String = "") {
        super();
        this.value = Math.max(0.0, Math.min(1.0, value));
        this.label = label;
    }

    override public function measure(constraint:Constraint):Size {
        var insets = getInsets();
        var fw = getFixedWidth();
        var maxW = switch (constraint) {
            case Exact(w, _): w;
            case AtMost(w, _): w;
            case Unbounded: 30;
        };
        return new Size(
            fw > 0 ? fw : maxW,
            1 + insets.verticalTotal()
        );
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var insets = getInsets();
        var inner = area.inner(insets);

        // Label takes some space at the start
        var labelW = 0;
        if (label.length > 0) {
            var display = label + " ";
            buffer.writeString(inner.x, inner.y, display, style);
            labelW = display.length;
        }

        // Percentage at the end
        var pctStr = Std.string(Std.int(value * 100)) + "%";
        var pctW = pctStr.length + 1; // " 100%"

        var barWidth = inner.width - labelW - pctW;
        if (barWidth < 3) barWidth = 3;

        var filledCells = value * barWidth;
        var fullCells = Std.int(filledCells);
        var fraction = filledCells - fullCells;

        var barStyle = style.clone();

        // Draw filled portion
        for (i in 0...fullCells) {
            buffer.set(inner.x + labelW + i, inner.y, "\u2588", barStyle); // full block
        }

        // Draw fractional cell using partial block characters
        if (fullCells < barWidth) {
            var partialChar = if (fraction >= 0.875) "\u2588"
                else if (fraction >= 0.75) "\u2589"
                else if (fraction >= 0.625) "\u258A"
                else if (fraction >= 0.5) "\u258B"
                else if (fraction >= 0.375) "\u258C"
                else if (fraction >= 0.25) "\u258D"
                else if (fraction >= 0.125) "\u258E"
                else "\u258F";

            if (fraction > 0.0) {
                buffer.set(inner.x + labelW + fullCells, inner.y, partialChar, barStyle);
            }
        }

        // Draw empty portion
        var emptyStyle = style.clone();
        emptyStyle.dim = true;
        var startEmpty = fullCells + (fraction > 0.0 ? 1 : 0);
        for (i in startEmpty...barWidth) {
            buffer.set(inner.x + labelW + i, inner.y, "\u2591", emptyStyle); // light shade
        }

        // Draw percentage
        buffer.writeString(inner.x + labelW + barWidth + 1, inner.y, pctStr, style);
    }
}
