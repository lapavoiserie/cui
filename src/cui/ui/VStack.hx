package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

class VStack extends View {
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

        var heights = distributeHeights(maxW, maxH);
        var totalH = 0;
        var widest = 0;
        var spacerCount = 0;

        for (i in 0...children.length) {
            if (Std.isOfType(children[i], Spacer)) {
                spacerCount++;
            } else {
                totalH += heights[i];
                var cs = children[i].measure(Constraint.AtMost(maxW, heights[i]));
                if (cs.width > widest) widest = cs.width;
            }
        }

        if (children.length > 1) totalH += spacing * (children.length - 1);

        var remaining = maxH - totalH;
        if (remaining > 0 && spacerCount > 0) {
            totalH = maxH;
        } else if (totalH > maxH) {
            totalH = maxH;
        }

        var w = fw > 0 ? fw : widest + insets.horizontalTotal();
        var h = fh > 0 ? fh : totalH + insets.verticalTotal();
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
        var heights = distributeHeights(inner.width, inner.height);

        // Measure with distributed heights
        var childSizes = new Array<Size>();
        var totalFixed = 0;
        var spacerCount = 0;

        for (i in 0...children.length) {
            if (Std.isOfType(children[i], Spacer)) {
                spacerCount++;
                childSizes.push(new Size(0, 0));
            } else {
                var cs = children[i].measure(Constraint.AtMost(inner.width, heights[i]));
                childSizes.push(cs);
                totalFixed += cs.height;
            }
        }

        if (children.length > 1) totalFixed += spacing * (children.length - 1);

        var spacerH = 0;
        var remaining = inner.height - totalFixed;
        if (remaining > 0 && spacerCount > 0) {
            spacerH = Std.int(remaining / spacerCount);
        }

        // Render children
        var yOffset = inner.y;
        for (i in 0...children.length) {
            if (yOffset >= inner.y + inner.height) break;

            var child = children[i];
            var cs = childSizes[i];
            var h = Std.isOfType(child, Spacer) ? spacerH : cs.height;

            if (yOffset + h > inner.y + inner.height) {
                h = inner.y + inner.height - yOffset;
            }
            if (h <= 0) { yOffset += spacing; continue; }

            var childArea = new Rect(inner.x, yOffset, inner.width, h);
            child.render(buffer, childArea);

            yOffset += h + spacing;
        }
    }

    function distributeHeights(availW:Int, availH:Int):Array<Int> {
        var nonSpacerCount = 0;
        for (child in children) {
            if (!Std.isOfType(child, Spacer)) nonSpacerCount++;
        }

        if (nonSpacerCount == 0) {
            return [for (_ in children) 0];
        }

        var totalSpacing = children.length > 1 ? spacing * (children.length - 1) : 0;
        var distributable = availH - totalSpacing;
        if (distributable < 0) distributable = 0;

        var fairShare = Std.int(distributable / nonSpacerCount);

        // Pass 1: measure with Unbounded to get natural heights
        var naturalHeights = new Array<Int>();
        for (child in children) {
            if (Std.isOfType(child, Spacer)) {
                naturalHeights.push(0);
            } else {
                var cs = child.measure(Constraint.AtMost(availW, 1000));
                naturalHeights.push(cs.height);
            }
        }

        // Check if natural sizes fit
        var totalNatural = 0;
        for (i in 0...children.length) {
            if (!Std.isOfType(children[i], Spacer)) {
                totalNatural += naturalHeights[i];
            }
        }

        if (totalNatural <= distributable) {
            return naturalHeights;
        }

        // Pass 2: compact children keep natural height, greedy ones share the rest
        var compactTotal = 0;
        var greedyCount = 0;
        for (i in 0...children.length) {
            if (Std.isOfType(children[i], Spacer)) continue;
            if (naturalHeights[i] <= fairShare) {
                compactTotal += naturalHeights[i];
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
            } else if (naturalHeights[i] <= fairShare) {
                result.push(naturalHeights[i]);
            } else {
                result.push(greedyShare);
            }
        }

        return result;
    }
}
