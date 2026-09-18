package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.modifiers.ViewModifier;
import cui.render.Buffer;
import cui.render.Style;

@:node("Text")
class Text extends View {
    @:prop("text") public var content:String;

    /**
        How the canon says this text is set (`nui.TextStyle`).

        A terminal keeps all five so that a tree it describes says what it was
        given, and honours the three it can: a weight past six hundred is bold,
        italic is italic, and digits are of one width already. A cell is one
        size and one font, so the scale and the family are carried and not
        drawn -- which is the honest answer, not a lack.
    **/
    @:prop public var scale(default, set):Null<nui.Scale> = null;

    @:prop public var family(default, set):Null<String> = null;

    @:prop public var weight(default, set):Null<Int> = null;

    @:prop("italic") public var slanted(default, set):Null<Bool> = null;

    @:prop("numbers") public var tabular(default, set):nui.Numbers = false;

    public function new(content:String) {
        super();
        this.content = content;
    }

    function set_scale(v:Null<nui.Scale>):Null<nui.Scale> { scale = v; return applied(); }

    function set_family(v:Null<String>):Null<String> { family = v; return applied(); }

    function set_weight(v:Null<Int>):Null<Int> { weight = v; return applied(); }

    function set_slanted(v:Null<Bool>):Null<Bool> { slanted = v; return applied(); }

    function set_tabular(v:nui.Numbers):nui.Numbers { tabular = v; return applied(); }

    /**
        What the style says, applied, whoever wrote it.

        This used to live at the end of `styled()`, so a heading set through
        that method was bold and a heading set by assigning `scale` was not.
        Nobody assigned `scale` until the generated builder did -- it fills a
        control's non-argument properties by assignment, which is what the
        declarations say they are -- and a received subtitle came out in plain
        text. Derived where it is read from rather than where one caller
        happened to put it.
    **/
    function applied<T>(?ignored:T):T {
        var heading = this.scale == Title || this.scale == Subtitle;
        if (heading || (this.weight != null && nui.TextStyle.isBold(this.weight))) bold();
        if (this.slanted == true) super.italic();
        return ignored;
    }

    /** Say how it is set; what a terminal can draw, it applies here. **/
    public function styled(?scale:nui.Scale, ?family:String, ?weight:Int, ?italic:Bool, ?tabular:nui.Numbers):Text {
        // `nui.Scale` normalises on the way in, so what arrives is one of the
        // four whether it came from an application or from a node.
        if (scale != null) this.scale = scale;
        if (family != null && family != "") this.family = family;
        if (weight != null) this.weight = nui.TextStyle.weightOf(weight);
        if (italic != null) this.slanted = italic;
        if (tabular) this.tabular = true;

        // A heading is heavier because it cannot be larger; a weight said
        // outright is the same request, made in the vocabulary of fonts. Done
        // by the setters above now, so an assignment gets it too.
        return this;
    }

    override public function measure(constraint:Constraint):Size {
        var insets = getInsets();
        var maxW = switch (constraint) {
            case Exact(w, _): w - insets.horizontalTotal();
            case AtMost(w, _): w - insets.horizontalTotal();
            case Unbounded: content.length;
        };

        var fw = getFixedWidth();
        if (fw > 0) maxW = fw - insets.horizontalTotal();

        if (maxW <= 0) maxW = content.length;

        var lines = wrapText(content, maxW);
        var textW = 0;
        for (line in lines) {
            if (line.length > textW) textW = line.length;
        }

        var fh = getFixedHeight();
        var h = fh > 0 ? fh : lines.length + insets.verticalTotal();
        var w = fw > 0 ? fw : textW + insets.horizontalTotal();

        return new Size(w, h);
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var borderStyle = getBorderStyle();
        var insets = getInsets();

        // Draw border
        if (borderStyle != cui.render.BorderStyle.None) {
            cui.layout.LayoutEngine.drawBorder(buffer, area, borderStyle, style);
        }

        var inner = area.inner(insets);
        var lines = wrapText(content, inner.width);
        var align = getAlignment();

        for (i in 0...lines.length) {
            if (i >= inner.height) break;
            var line = lines[i];
            var xOffset = switch (align) {
                case Left: 0;
                case Center: Std.int((inner.width - line.length) / 2);
                case Right: inner.width - line.length;
            };
            if (xOffset < 0) xOffset = 0;
            buffer.writeString(inner.x + xOffset, inner.y + i, line, style);
        }
    }

    static function wrapText(text:String, maxWidth:Int):Array<String> {
        if (maxWidth <= 0) return [text];

        var lines = new Array<String>();

        // Break on the newlines the text already carries, before wrapping on
        // width. Without this a string short enough to fit was pushed whole --
        // its "\n" included -- so everything after the first line vanished at
        // the point the terminal met a control character it could not draw. A
        // caption written on two lines showed one, and only when it was short
        // enough to fit; longer text wrapped and looked fine, which is why it
        // went unnoticed.
        for (paragraph in text.split("\n")) {
            wrapParagraph(paragraph, maxWidth, lines);
        }

        if (lines.length == 0) lines.push("");
        return lines;
    }

    /** Wrap one newline-free run into `lines`, breaking at spaces. **/
    static function wrapParagraph(text:String, maxWidth:Int, lines:Array<String>):Void {
        if (text.length == 0) {
            lines.push("");
            return;
        }

        var remaining = text;

        while (remaining.length > 0) {
            if (remaining.length <= maxWidth) {
                lines.push(remaining);
                break;
            }

            // Find last space within maxWidth
            var breakAt = maxWidth;
            var lastSpace = -1;
            for (j in 0...maxWidth) {
                if (remaining.charAt(j) == " ") lastSpace = j;
            }
            if (lastSpace > 0) breakAt = lastSpace;

            lines.push(remaining.substr(0, breakAt));
            remaining = remaining.substr(breakAt);
            // Skip leading space after break
            if (remaining.length > 0 && remaining.charAt(0) == " ") {
                remaining = remaining.substr(1);
            }
        }
    }
}
