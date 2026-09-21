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

/**
	CheckboxBinding, or the cell itself.

	The class below is the implementation and stays exactly what it was. This
	abstract in front of it carries the one thing a class cannot declare -- an
	implicit cast -- so a field, a toggle or a slider can be handed the state
	cell directly.

	`mui`'s markup binds the CELL, because that is what a view written by hand
	binds, and it could not reach any of these: `<Toggle isOn={lit_}/>` failed
	to compile with *should be CheckboxBinding* on a backend that declares the tag and
	draws it. `pui` has the same shape for the same reason
	(`pui.ui.TextInputBinding`).
**/
@:forward
abstract CheckboxBinding(CheckboxBindingCell) from CheckboxBindingCell to CheckboxBindingCell {
	public inline function new(getFn:Void->Bool, setFn:Bool->Void)
		this = new CheckboxBindingCell(getFn, setFn);

	@:from public static inline function fromState(state:BoolState):CheckboxBinding
		return CheckboxBindingCell.fromState(state);
}

class CheckboxBindingCell {
    /** The cell this was made from, if any. See `cui.state.Binding.source`. **/
    public var source(default, null):Dynamic = null;

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

    public static function fromState(state:BoolState):CheckboxBindingCell {
        var made = new CheckboxBindingCell(
            () -> state.get(),
            (v) -> state.set(v)
        );
        made.source = state;
        return made;
    }
}

@:node("Toggle")
class Checkbox extends View {
    @:prop var label:String;
    @:prop("isOn", "onToggle") var binding:CheckboxBinding;

    override public function focusIdentity():Dynamic {
        return binding == null ? null : binding.source;
    }

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
