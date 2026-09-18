package cui.ui;

import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;
import cui.render.Style;
import cui.render.Color;
import cui.state.State;

/**
    A horizontal slider rendered as a track with a fill indicator.

    Renders as: [████████░░░░░░░░] 50%

    Left/Right arrow keys adjust the value by `step`.
**/
@:node("Slider")
class Slider extends View {
    @:prop("value", "onValue") var binding:SliderBinding;
    @:prop var min:Float;
    @:prop var max:Float;
    var step:Float;

    public function new(binding:SliderBinding, min:Float = 0.0, max:Float = 1.0, step:Float = 0.05) {
        super();
        this.binding = binding;
        this.min = min;
        this.max = max;
        this.step = step;
        this.focusable = true;
    }

    override public function measure(constraint:Constraint):Size {
        var fw = getFixedWidth();
        var w = switch (constraint) {
            case Exact(w, _): w;
            case AtMost(w, _): fw > 0 ? fw : (w < 24 ? w : 24);
            case Unbounded: 24;
        };
        return new Size(fw > 0 ? fw : w, 1);
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        frame = area;
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var focused = isFocused();

        var value = binding.get();
        var ratio = if (max > min) (value - min) / (max - min) else 0.0;
        if (ratio < 0) ratio = 0;
        if (ratio > 1) ratio = 1;

        // Reserve 5 chars for percentage label: " 100%"
        var trackWidth = area.width - 5;
        if (trackWidth < 4) trackWidth = 4;

        var filledCount = Std.int(ratio * trackWidth);
        if (filledCount > trackWidth) filledCount = trackWidth;

        var renderStyle = style.clone();
        if (focused) renderStyle.inverse = true;

        // Draw filled portion
        for (x in 0...filledCount) {
            buffer.set(area.x + x, area.y, "\u2588", renderStyle);
        }
        // Draw empty portion
        var emptyStyle = style.clone();
        if (focused) emptyStyle.inverse = true;
        emptyStyle.dim = true;
        for (x in filledCount...trackWidth) {
            buffer.set(area.x + x, area.y, "\u2591", emptyStyle);
        }

        // Draw percentage
        var pct = Std.string(Std.int(ratio * 100));
        var label = ' ${pct}%';
        buffer.writeString(area.x + trackWidth, area.y, label, style);
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Right:
                        var v = binding.get() + step;
                        if (v > max) v = max;
                        binding.set(v);
                        return true;
                    case Left:
                        var v = binding.get() - step;
                        if (v < min) v = min;
                        binding.set(v);
                        return true;
                    default:
                }
            default:
        }
        return false;
    }
}

class SliderBinding {
    var _get:Void->Float;
    var _set:Float->Void;

    public function new(getFn:Void->Float, setFn:Float->Void) {
        _get = getFn;
        _set = setFn;
    }

    public function get():Float {
        return _get();
    }

    public function set(v:Float):Void {
        _set(v);
    }

    public static function fromState(state:FloatState):SliderBinding {
        return new SliderBinding(
            () -> state.get(),
            (v) -> state.set(v)
        );
    }
}
