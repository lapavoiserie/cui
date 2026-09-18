package cui.ui;

import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;
import cui.render.Style;
import cui.state.State;

class CheckboxBinding {
    var _get:Void->Bool;
    var _set:Bool->Void;

    public function new(getFn:Void->Bool, setFn:Bool->Void) {
        _get = getFn;
        _set = setFn;
    }

    public function get():Bool {
        return _get();
    }

    public function set(v:Bool):Void {
        _set(v);
    }

    public function toggle():Void {
        _set(!_get());
    }

    public static function fromState(state:BoolState):CheckboxBinding {
        return new CheckboxBinding(
            () -> state.get(),
            (v) -> state.set(v)
        );
    }
}

@:node("Toggle")
class Checkbox extends View {
    @:prop var label:String;
    @:prop("isOn", "onToggle") var binding:CheckboxBinding;

    public function new(label:String, binding:CheckboxBinding) {
        super();
        this.label = label;
        this.binding = binding;
        this.focusable = true;
    }

    override public function measure(constraint:Constraint):Size {
        // [x] label  or  [ ] label
        var w = 4 + label.length;
        var fw = getFixedWidth();
        return new Size(fw > 0 ? fw : w, 1);
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        frame = area;
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var checked = binding.get();
        var focused = isFocused();

        var boxStyle = style.clone();
        if (focused) boxStyle.inverse = true;

        var box = checked ? "[\u2713]" : "[ ]";
        buffer.writeString(area.x, area.y, box, boxStyle);
        buffer.writeString(area.x + 4, area.y, label, style);
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Enter:
                        binding.toggle();
                        return true;
                    case Char(c):
                        if (c == " ") {
                            binding.toggle();
                            return true;
                        }
                    default:
                }
            default:
        }
        return false;
    }
}
