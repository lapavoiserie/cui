package cui.ui;

import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;
import cui.render.Style;
import cui.state.Binding;

@:node("TextInput")
class Input extends View {
    @:prop("text", "onText") var binding:Binding<String>;
    @:prop var placeholder:String;

    /**
        Where the caret is, and whose it is -- kept across the rebuild that
        typing causes.

        cui rebuilds the whole tree on every state write, so this object is
        thrown away mid-word and the constructor put the caret back at the end
        of the text. Moving the caret was therefore impossible: `Left`
        decremented it, asked for a redraw, and the redraw built a fresh field
        whose caret was at the end again. Typing appeared to work only because
        the end is where it already wanted to be; editing in the middle of a
        word never did. `abc`, Left, Left, `X` gave `abcX`.

        **Keyed by the focus index, not by the view.** Identity in cui is the
        place and never the pointer -- a rebuilt tree is all new objects and the
        same ring -- and only the focused field has a caret worth keeping, so
        one slot is enough. The same argument `pui.ui.TextInput` makes for its
        blink phase.
    **/
    static var caretOwner:Int = -1;

    static var caret:Int = 0;

    /**
        The text the caret was last placed against.

        The focus index alone is not an identity: another tree can put a
        different field in the same slot, and the caret would carry over into
        it. So the caret is kept only while the text under it is still the text
        it was measured against -- every edit and every move records the value
        it left behind. A value changed from elsewhere therefore sends the caret
        to the end, which is the same answer as a field just focused.
    **/
    static var caretText:String = "";

    /**
        What has been typed into a received field but has not come back yet.

        The rule nui's canon states for a `TextInput`: a received value is not
        applied to a field somebody is typing in. Only meaningful when
        `receivesValue` is set -- for an ordinary field the binding is written
        by the field and read straight back, and there is nothing to reconcile.
    **/
    static var draftOwner:Int = -1;

    static var draft:Null<String> = null;

    /**
        Whether this field's value is somebody else's: set by
        `cui.nui.NodeRenderer` for a field built from a received tree, whose
        binding is fabricated afresh on every build from a node that lags a
        keystroke or two behind while somebody types.
    **/
    public var receivesValue:Bool = false;

    /**
        What Enter does, if anything.

        nui's canon states the pair: `onText` says the value is live, every
        keystroke worth hearing; `onSubmit` says it is an act -- a page address
        that would load on every letter, a path, a name that saves. A field
        carrying only the second keeps what is being typed and tells nobody
        until this runs.

        Null for a field with no such act, and then Enter is not this view's key.
    **/
    @:action("onSubmit") public var onSubmit:Null<Void->Void> = null;

    public function new(binding:Binding<String>, placeholder:String = "") {
        super();
        this.binding = binding;
        this.placeholder = placeholder;
        this.focusable = true;
    }

    /** Which slot of the focus ring this field is, or -1 when it has none. **/
    inline function slot():Int {
        return View.focusManager == null ? -1 : View.focusManager.focusIndex;
    }

    /**
        Whether the value is drawn as marks rather than as itself.

        A password field is a field in every respect but this one, so it is one
        flag here rather than a second class -- `cui.ui.Password` sets it, and
        nui's canon states `PasswordInput` as its own TYPE for the reason a
        flag on the wire would fail open. The distinction is between a wire,
        where a renderer may not know the flag, and a class in this library,
        where it cannot be missed.
    **/
    public var masked:Bool = false;

    /** What is DRAWN: the text, or one mark per character of it. **/
    function displayText():String {
        var body = text();
        if (!masked) return body;
        var out = new StringBuf();
        for (_ in 0...body.length) out.add("\u2022");
        return out.toString();
    }

    /** What the field shows: the binding, or the draft while it is being typed in. **/
    function text():String {
        if (receivesValue && isFocused() && draft != null && draftOwner == slot()) return draft;
        return binding.get();
    }

    /** Where the caret is. At the end of the text for a field nobody is in. **/
    function cursor():Int {
        var now = text();
        if (!isFocused()) return now.length;
        if (caretOwner != slot() || caretText != now) {
            caretOwner = slot();
            caretText = now;
            caret = now.length;
        }
        if (caret > now.length) caret = now.length;
        if (caret < 0) caret = 0;
        return caret;
    }

    function setCursor(at:Int):Void {
        caretOwner = slot();
        caretText = text();
        caret = at;
    }

    /** Write an edit: the draft first, so the rebuild cannot land between them. **/
    function commit(value:String, at:Int):Void {
        if (receivesValue) {
            draft = value;
            draftOwner = slot();
        }
        // The caret is recorded against the value being written, not the one
        // being replaced: the rebuild rides on `binding.set` below, and the
        // field that comes back has to recognise its own text.
        caretOwner = slot();
        caretText = value;
        caret = at;
        binding.set(value);
    }

    override public function measure(constraint:Constraint):Size {
        var insets = getInsets();
        var fw = getFixedWidth();
        var maxW = switch (constraint) {
            case Exact(w, _): w;
            case AtMost(w, _): Std.int(Math.min(30, w));
            case Unbounded: 30;
        };
        var fh = getFixedHeight();
        return new Size(
            fw > 0 ? fw : maxW,
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
        var text = displayText();
        var focused = isFocused();
        var cursorPos = cursor();

        if (text.length == 0 && !focused) {
            // Show placeholder
            var phStyle = style.clone();
            phStyle.dim = true;
            buffer.writeString(inner.x, inner.y, placeholder.substr(0, inner.width), phStyle);
        } else {
            // Show text content
            var displayText = text;
            // Scroll if text is longer than field width
            var scrollOffset = 0;
            if (cursorPos >= inner.width) {
                scrollOffset = cursorPos - inner.width + 1;
            }
            displayText = displayText.substr(scrollOffset, inner.width);
            buffer.writeString(inner.x, inner.y, displayText, style);

            // Fill remaining with spaces
            var remaining = inner.width - displayText.length;
            for (i in 0...remaining) {
                buffer.set(inner.x + displayText.length + i, inner.y, " ", style);
            }

            // Draw cursor
            if (focused) {
                var cursorX = inner.x + cursorPos - scrollOffset;
                if (cursorX >= inner.x && cursorX < inner.x + inner.width) {
                    var cursorStyle = style.clone();
                    cursorStyle.inverse = true;
                    var charAtCursor = cursorPos < text.length ? text.charAt(cursorPos) : " ";
                    buffer.set(cursorX, inner.y, charAtCursor, cursorStyle);
                }
            }
        }

        // Underline the whole field when focused
        if (focused) {
            var ulStyle = style.clone();
            ulStyle.underline = true;
            // Just mark the borders of the field area
        }
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                var text = this.text();
                var cursorPos = cursor();
                switch (key.code) {
                    case Char(c):
                        if (!key.ctrl && !key.alt) {
                            // Insert character at cursor position
                            commit(text.substr(0, cursorPos) + c + text.substr(cursorPos), cursorPos + 1);
                            return true;
                        }
                    case Backspace:
                        if (cursorPos > 0) {
                            commit(text.substr(0, cursorPos - 1) + text.substr(cursorPos), cursorPos - 1);
                            return true;
                        }
                    case Delete:
                        if (cursorPos < text.length) {
                            commit(text.substr(0, cursorPos) + text.substr(cursorPos + 1), cursorPos);
                            return true;
                        }
                    // A caret move is not an edit: it writes no value, so it
                    // asks for the redraw itself. It survives that redraw
                    // because the caret is not in this object.
                    case Left:
                        if (cursorPos > 0) {
                            setCursor(cursorPos - 1);
                            cui.state.State.StateBase.markDirty();
                        }
                        return true;
                    case Right:
                        if (cursorPos < text.length) {
                            setCursor(cursorPos + 1);
                            cui.state.State.StateBase.markDirty();
                        }
                        return true;
                    // Submitting is an act: some fields report only here.
                    case Enter:
                        if (onSubmit != null) {
                            onSubmit();
                            cui.state.State.StateBase.markDirty();
                            return true;
                        }
                        return false;

                    case Home:
                        setCursor(0);
                        cui.state.State.StateBase.markDirty();
                        return true;
                    case End:
                        setCursor(text.length);
                        cui.state.State.StateBase.markDirty();
                        return true;
                    default:
                }
            default:
        }
        return false;
    }
}
