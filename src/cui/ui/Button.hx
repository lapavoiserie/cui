package cui.ui;

import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;
import cui.render.Style;

class Button extends View {
    public var label(default, null):String;

    /**
        A name from the shared vocabulary (`nui.Icons`), drawn as its character
        before the label -- or alone, when the label is empty.
    **/
    public var icon(default, null):Null<String>;

    var action:Void->Void;

    public function new(label:String, action:Void->Void, ?icon:String) {
        super();
        this.label = label;
        this.action = action;
        this.icon = icon != null && cui.nui.Icons.glyphOf(icon) != null ? icon : null;
        this.focusable = true;
    }

    /** What sits between the brackets: the character, a space, the label. **/
    function inside():String {
        var glyph = icon == null ? null : cui.nui.Icons.glyphOf(icon);
        if (glyph == null) return label;
        return label == "" ? glyph : glyph + " " + label;
    }

    /** Cells, not code points: a stroked character is two of them in one cell. **/
    function insideWidth():Int {
        var glyph = icon == null ? null : cui.nui.Icons.glyphOf(icon);
        if (glyph == null) return label.length;
        return label == "" ? 1 : 2 + label.length;
    }

    /**
        Run the button's action.

        The closure itself stays private on purpose: a description layer must be
        able to *trigger* an action without ever holding the handler. See nui's
        node model, where actions cross as identifiers and never as closures.
    **/
    public function invoke():Void {
        if (action != null) action();
    }

    override public function measure(constraint:Constraint):Size {
        var insets = getInsets();
        // Button renders as: [ label ] with 1 cell padding on each side
        var contentW = insideWidth() + 4; // "[ " + what is inside + " ]"
        var fw = getFixedWidth();
        var fh = getFixedHeight();
        return new Size(
            fw > 0 ? fw : contentW + insets.horizontalTotal(),
            fh > 0 ? fh : 1 + insets.verticalTotal()
        );
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        frame = area;
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var borderStyle = getBorderStyle();
        var insets = getInsets();

        if (borderStyle != cui.render.BorderStyle.None) {
            cui.layout.LayoutEngine.drawBorder(buffer, area, borderStyle, style);
        }

        var inner = area.inner(insets);

        // Apply focus styling
        var renderStyle = style.clone();
        if (isFocused()) {
            renderStyle.inverse = true;
        }

        var display = "[ " + inside() + " ]";
        var cells = insideWidth() + 4;
        var align = getAlignment();
        var xOffset = switch (align) {
            case Left: 0;
            case Center: Std.int((inner.width - cells) / 2);
            case Right: inner.width - cells;
        };
        if (xOffset < 0) xOffset = 0;

        buffer.writeString(inner.x + xOffset, inner.y, display, renderStyle);
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Enter:
                        action();
                        return true;
                    case Char(c):
                        if (c == " ") {
                            action();
                            return true;
                        }
                    default:
                }
            default:
        }
        return false;
    }
}
