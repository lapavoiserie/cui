package cui.ui;

import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.event.MouseEvent;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;
import cui.render.Style;
import cui.state.State;

/**
	ScrollOffset, or the cell itself.

	The class below is the implementation and stays exactly what it was. This
	abstract in front of it carries the one thing a class cannot declare -- an
	implicit cast -- so a field, a toggle or a slider can be handed the state
	cell directly.

	`mui`'s markup binds the CELL, because that is what a view written by hand
	binds, and it could not reach any of these: `<Toggle isOn={lit_}/>` failed
	to compile with *should be ScrollOffset* on a backend that declares the tag and
	draws it. `pui` has the same shape for the same reason
	(`pui.ui.TextInputBinding`).
**/
@:forward
abstract ScrollOffset(ScrollOffsetCell) from ScrollOffsetCell to ScrollOffsetCell {
	public inline function new(getFn:Void->Int, setFn:Int->Void)
		this = new ScrollOffsetCell(getFn, setFn);

	@:from public static inline function fromState(state:IntState):ScrollOffset
		return ScrollOffsetCell.fromState(state);
}

class ScrollOffsetCell {
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

    public static function fromState(state:IntState):ScrollOffsetCell {
        return new ScrollOffsetCell(
            () -> state.get(),
            (v) -> state.set(v)
        );
    }
}

/**
	A child taller than the space it is given, and a window onto it.

	## The offset is optional, and that is the canon

	It was required: `new ScrollView(child, offset)`, with the application
	holding the position. The canon's `ScrollView` takes only its content --
	`pui`'s does, `sui`'s does -- because where a view has been scrolled to is
	the control's own business, not something a screen has to carry a cell for.
	So markup could not write one here at all.

	Given no binding, it keeps its own position. An application that wants to
	read the position, restore it, or move it from elsewhere passes one, and
	nothing about that changed.
**/
@:node("ScrollView")
@:content("content")
class ScrollView extends View {
    var child:View;
    var offsetBinding:ScrollOffset;
    var contentHeight:Int;
    var visibleHeight:Int;

    /** Where this view is scrolled to when nobody outside holds it. **/
    var ownOffset:Int = 0;

    /**
        @param content what scrolls. Several children are stacked, because the
        canon's `ScrollView` holds a list and this one held exactly one: markup
        wrapping twelve rows in a scroll view kept the FIRST and dropped eleven
        without a word. A single view is still a single view.
    **/
    public function new(content:Array<View>, ?offset:ScrollOffset) {
        var child = content == null || content.length == 0
            ? new VStack([], 0)
            : (content.length == 1 ? content[0] : new VStack(content, 0));
        super();
        this.child = child;
        this.children = [child];
        this.offsetBinding = offset != null
            ? offset
            : new ScrollOffset(function() return ownOffset, function(v) ownOffset = v);
        this.contentHeight = 0;
        this.visibleHeight = 0;
        this.focusable = true;
    }

    function getOffset():Int {
        return offsetBinding.get();
    }

    function setOffset(v:Int):Void {
        var maxScroll = contentHeight - visibleHeight;
        if (maxScroll < 0) maxScroll = 0;
        if (v > maxScroll) v = maxScroll;
        if (v < 0) v = 0;
        offsetBinding.set(v);
    }

    override public function measure(constraint:Constraint):Size {
        var insets = getInsets();
        var maxW = switch (constraint) {
            case Exact(w, _): w;
            case AtMost(w, _): w;
            case Unbounded: 60;
        };
        var maxH = switch (constraint) {
            case Exact(_, h): h;
            case AtMost(_, h): h;
            case Unbounded: 20;
        };
        var fw = getFixedWidth();
        var fh = getFixedHeight();

        // As tall as its content, and no taller than the box it was offered.
        //
        // It used to ask for the whole box unconditionally, which is right for
        // the one place it had ever been used -- a scroll view AS the screen --
        // and wrong as one of six children of a stack: two greedy siblings
        // divided the height between them and the other four got none. The
        // kitchen sink drew exactly one line on this backend for that reason.
        //
        // Content taller than the box still gets the box, which is the case
        // that scrolls; this only stops an empty or short one from taking
        // space it has nothing to put in.
        var content = child == null
            ? 0
            : child.measure(Constraint.AtMost(maxW - insets.horizontalTotal(), 10000)).height;
        var natural = content + insets.verticalTotal();
        if (natural > maxH) natural = maxH;

        return new Size(
            fw > 0 ? fw : maxW,
            fh > 0 ? fh : natural
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
        visibleHeight = inner.height;

        // Measure child at full height to know content size
        var childSize = child.measure(Constraint.AtMost(inner.width - 1, 10000));
        contentHeight = childSize.height;

        // Clamp scroll offset
        var scrollOffset = getOffset();
        var maxScroll = contentHeight - inner.height;
        if (maxScroll < 0) maxScroll = 0;
        if (scrollOffset > maxScroll) scrollOffset = maxScroll;
        if (scrollOffset < 0) scrollOffset = 0;

        // Render child into a temporary buffer, then copy the visible portion
        var childBuffer = new Buffer(inner.width - 1, contentHeight);
        child.render(childBuffer, new Rect(0, 0, inner.width - 1, contentHeight));

        // Copy visible region
        for (y in 0...inner.height) {
            var srcY = y + scrollOffset;
            if (srcY >= contentHeight) break;
            for (x in 0...(inner.width - 1)) {
                var cell = childBuffer.get(x, srcY);
                buffer.set(inner.x + x, inner.y + y, cell.char, cell.style);
            }
        }

        // Draw scrollbar
        if (contentHeight > inner.height) {
            var barHeight = Std.int(Math.max(1, inner.height * inner.height / contentHeight));
            var barPos = Std.int(scrollOffset * (inner.height - barHeight) / Math.max(1, maxScroll));
            var scrollStyle = style.clone();
            scrollStyle.dim = true;
            var scrollX = inner.x + inner.width - 1;
            for (y in 0...inner.height) {
                var ch = (y >= barPos && y < barPos + barHeight) ? "\u2588" : "\u2591";
                buffer.set(scrollX, inner.y + y, ch, scrollStyle);
            }
        }
    }

    override public function handleEvent(event:Event):Bool {
        var prev = getOffset();

        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Up:    setOffset(prev - 1);
                    case Down:  setOffset(prev + 1);
                    case PageUp:  setOffset(prev - visibleHeight);
                    case PageDown: setOffset(prev + visibleHeight);
                    default: return false;
                }
                return getOffset() != prev;
            case Mouse(mouse):
                if (mouse.button == ScrollUp) {
                    setOffset(prev - 3);
                    return getOffset() != prev;
                } else if (mouse.button == ScrollDown) {
                    setOffset(prev + 3);
                    return getOffset() != prev;
                }
            default:
        }
        return false;
    }
}
