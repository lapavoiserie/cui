package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

class HStack extends View {
    public var spacing(default, null):Int;

    public function new(children:Array<View>, spacing:Int = 0) {
        super();
        this.children = children;
        this.spacing = spacing;
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

        var widths = distributeWidths(maxW, maxH);
        var totalW = 0;
        var tallest = 0;
        var spacerCount = 0;

        for (i in 0...children.length) {
            if (Std.isOfType(children[i], Spacer)) {
                spacerCount++;
            } else {
                totalW += widths[i];
                var cs = children[i].measure(Constraint.AtMost(widths[i], maxH));
                if (cs.height > tallest) tallest = cs.height;
            }
        }

        if (children.length > 1) totalW += spacing * (children.length - 1);

        var remaining = maxW - totalW;
        if (remaining > 0 && spacerCount > 0) {
            totalW = maxW;
        }

        var w = fw > 0 ? fw : totalW + insets.horizontalTotal();
        var h = fh > 0 ? fh : tallest + insets.verticalTotal();
        return new Size(w, h);
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
        var widths = distributeWidths(inner.width, inner.height);

        // Measure with distributed widths
        var childSizes = new Array<Size>();
        var totalFixed = 0;
        var spacerCount = 0;

        for (i in 0...children.length) {
            if (Std.isOfType(children[i], Spacer)) {
                spacerCount++;
                childSizes.push(new Size(0, 0));
            } else {
                var cs = children[i].measure(Constraint.AtMost(widths[i], inner.height));
                childSizes.push(cs);
                totalFixed += cs.width;
            }
        }

        if (children.length > 1) totalFixed += spacing * (children.length - 1);

        var spacerW = 0;
        var remaining = inner.width - totalFixed;
        if (remaining > 0 && spacerCount > 0) {
            spacerW = Std.int(remaining / spacerCount);
        }

        // Render children
        var xOffset = inner.x;
        for (i in 0...children.length) {
            if (xOffset >= inner.x + inner.width) break;

            var child = children[i];
            var cs = childSizes[i];
            var w = Std.isOfType(child, Spacer) ? spacerW : cs.width;

            if (xOffset + w > inner.x + inner.width) {
                w = inner.x + inner.width - xOffset;
            }
            if (w <= 0) { xOffset += spacing; continue; }

            var childArea = new Rect(xOffset, inner.y, w, inner.height);
            child.render(buffer, childArea);

            xOffset += w + spacing;
        }
    }

    function distributeWidths(availW:Int, availH:Int):Array<Int> {
        var nonSpacerCount = 0;
        for (child in children) {
            if (!Std.isOfType(child, Spacer)) nonSpacerCount++;
        }

        if (nonSpacerCount == 0) {
            return [for (_ in children) 0];
        }

        var totalSpacing = children.length > 1 ? spacing * (children.length - 1) : 0;
        var distributable = availW - totalSpacing;
        if (distributable < 0) distributable = 0;

        var fairShare = Std.int(distributable / nonSpacerCount);

        // Pass 1: measure with Unbounded to get natural widths
        var naturalWidths = new Array<Int>();
        for (child in children) {
            if (Std.isOfType(child, Spacer)) {
                naturalWidths.push(0);
            } else {
                var cs = child.measure(Constraint.Unbounded);
                naturalWidths.push(cs.width);
            }
        }

        // Check if natural sizes fit
        var totalNatural = 0;
        for (i in 0...children.length) {
            if (!Std.isOfType(children[i], Spacer)) {
                totalNatural += naturalWidths[i];
            }
        }

        // If everything fits naturally, use natural widths
        if (totalNatural <= distributable) {
            return naturalWidths;
        }

        // Pass 2: compact children keep natural width, greedy ones share the rest
        var compactTotal = 0;
        var greedyCount = 0;
        for (i in 0...children.length) {
            if (Std.isOfType(children[i], Spacer)) continue;
            if (naturalWidths[i] <= fairShare) {
                compactTotal += naturalWidths[i];
            } else {
                greedyCount++;
            }
        }

        var greedyShare = 0;
        if (greedyCount > 0) {
            greedyShare = Std.int((distributable - compactTotal) / greedyCount);
            if (greedyShare < 1) greedyShare = 1;
        }

        var result = new Array<Int>();
        for (i in 0...children.length) {
            if (Std.isOfType(children[i], Spacer)) {
                result.push(0);
            } else if (naturalWidths[i] <= fairShare) {
                result.push(naturalWidths[i]);
            } else {
                result.push(greedyShare);
            }
        }

        return result;
    }
}
