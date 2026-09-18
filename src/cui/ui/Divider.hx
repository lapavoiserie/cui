package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

@:node("Divider")
class Divider extends View {
    var horizontal:Bool;
    var char:String;

    public function new(horizontal:Bool = true, ?char:String) {
        super();
        this.horizontal = horizontal;
        this.char = char != null ? char : (horizontal ? "\u2500" : "\u2502");
    }

    override public function measure(constraint:Constraint):Size {
        // Divider measures to minimal size; parent stretches it during render
        return switch (constraint) {
            case Exact(w, h): horizontal ? new Size(w, 1) : new Size(1, 1);
            case AtMost(w, _): horizontal ? new Size(w, 1) : new Size(1, 1);
            case Unbounded: new Size(1, 1);
        };
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        if (isHidden()) return;
        var style = getEffectiveStyle();

        if (horizontal) {
            for (x in 0...area.width) {
                buffer.set(area.x + x, area.y, char, style);
            }
        } else {
            for (y in 0...area.height) {
                buffer.set(area.x, area.y + y, char, style);
            }
        }
    }
}
