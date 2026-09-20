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
    A choice among options, on one row: `Transition ‹ Mix › 2/4`.

    ## Why it does not drop down

    Every other backend opens a list over the panel. `pui` had to build an
    overlay layer to do it, `aui` uses Material's popup, Silica and WinUI have
    menus of their own. A terminal has none: `cui`'s buffer is a grid of cells
    with **no z-order** — `cui.mui.ZStack` already says so out loud, and stacks
    its children instead of overlaying them. A list drawn under a picker would
    have to erase the rows it covers and put them back, which is a second
    renderer, not a control.

    So this one cycles. Left and Right move through the options, Enter and
    Space take the next one, and the position is printed beside the value
    because a list of four that shows one of them must say so. The same shape
    `Slider` already has, which is what a terminal's arrow keys mean here.

    Whoever holds the options sees no difference: the index is a binding, the
    choice is a write, and `cui.nui.Describe` sends the canonical `Picker` with
    a `Text` child per option whatever this draws.

    If the buffer ever gains a z-order, this becomes a drop-down and the rest
    of the library does not change.
**/
class PickerBinding {
    var _get:Void->Int;
    var _set:Int->Void;

    public function new(getFn:Void->Int, setFn:Int->Void) {
        _get = getFn;
        _set = setFn;
    }

    public function get():Int {
        return _get();
    }

    public function set(v:Int):Void {
        _set(v);
    }

    public static function fromState(state:IntState):PickerBinding {
        return new PickerBinding(
            () -> state.get(),
            (v) -> state.set(v)
        );
    }
}

@:node("Picker")
class Picker extends View {
    /** The arrows either side of the value: there is more to the left, to the right. **/
    static inline var LEFT = "‹";

    static inline var RIGHT = "›";

    @:prop public var label:String;

    /** One `Text` child per option, as the canon says. **/
    @:children("Text", "text") public var options:Array<String>;

    @:prop("selectedIndex", "onSelect") var binding:PickerBinding;

    public function new(label:String, options:Array<String>, binding:PickerBinding) {
        super();
        this.label = label;
        this.options = options == null ? [] : options;
        this.binding = binding;
        this.focusable = true;
    }

    /** The index actually showing: inside the list, or none when it is empty. **/
    public function index():Int {
        if (options.length == 0) return -1;
        var at = binding.get();
        if (at < 0) return 0;
        if (at >= options.length) return options.length - 1;
        return at;
    }

    public function chosen():String {
        var at = index();
        return at < 0 ? "" : options[at];
    }

    /** The widest option, so the row does not change width as it cycles. **/
    function valueWidth():Int {
        var widest = 0;
        for (option in options)
            if (option.length > widest) widest = option.length;
        return widest;
    }

    function position():String {
        var at = index();
        return options.length == 0 ? "" : ' ${at + 1}/${options.length}';
    }

    override public function measure(constraint:Constraint):Size {
        // label + " ‹ " + value + " › " + position
        var w = (label.length == 0 ? 0 : label.length + 1) + 4 + valueWidth() + position().length;
        var fw = getFixedWidth();
        return new Size(fw > 0 ? fw : w, 1);
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        frame = area;
        if (isHidden()) return;

        var style = getEffectiveStyle();
        var focused = isFocused();

        // Everything below is cut at this control's own right edge. Nothing
        // was, and `Buffer.writeString` stops at the TERMINAL's edge -- so a
        // picker narrower than its label and its value wrote straight over
        // whatever stood beside it, which is what a segmented picker did in
        // the Farceur window and what `pui.ui.Picker` now cuts.
        var edge = area.x + area.width;

        var x = area.x;
        if (label.length > 0) {
            buffer.writeString(x, area.y, label, style, edge);
            x += label.length + 1;
        }

        // Dim on the side there is nothing left to go, which is how a terminal
        // says "this end" without a scrollbar.
        var at = index();
        var arrow = style.clone();
        if (focused) arrow.inverse = true;

        var left = arrow.clone();
        if (at <= 0) left.dim = true;
        buffer.writeString(x, area.y, LEFT, left, edge);

        var value = style.clone();
        if (focused) value.inverse = true;
        buffer.writeString(x + 2, area.y, chosen(), value, edge);

        var right = arrow.clone();
        if (at < 0 || at >= options.length - 1) right.dim = true;
        buffer.writeString(x + 2 + valueWidth() + 1, area.y, RIGHT, right, edge);

        var trail = style.clone();
        trail.dim = true;
        buffer.writeString(x + 4 + valueWidth(), area.y, position(), trail, edge);
    }

    /** Move by one, staying inside the list. Answers whether anything moved. **/
    function move(by:Int):Bool {
        if (options.length == 0) return false;
        var at = index() + by;
        if (at < 0) at = 0;
        if (at >= options.length) at = options.length - 1;
        if (at == index()) return false;
        binding.set(at);
        return true;
    }

    /** The next one, back to the first past the end: what Enter does, and what
        makes a list of two reachable with one key. **/
    function advance():Bool {
        if (options.length == 0) return false;
        var at = index() + 1;
        binding.set(at >= options.length ? 0 : at);
        return true;
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    // Taken whether or not anything moved. A picker at the end
                    // of its list has answered Right -- with "no" -- and a key
                    // it declined would go on to whatever else in the tree
                    // wants arrows, which is how the first picker on a panel
                    // ended up moving for the fifth one's keystroke.
                    case Right:
                        move(1);
                        return true;
                    case Left:
                        move(-1);
                        return true;
                    case Enter:
                        return advance();
                    case Char(c):
                        if (c == " ") return advance();
                    default:
                }
            default:
        }
        return false;
    }
}
