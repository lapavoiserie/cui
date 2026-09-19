package cui;

import cui.layout.Constraint;
import cui.layout.Edge;
import cui.layout.Rect;
import cui.layout.Size;
import cui.modifiers.ViewModifier;
import cui.render.BorderStyle;
import cui.render.Buffer;
import cui.render.Color;
import cui.render.Style;
import cui.event.Event;
import cui.focus.FocusManager;

class View {
    public var children:Array<View>;
    public var modifiers:Array<ViewModifier>;
    public var frame:Rect;
    public var focusable:Bool;

    // Global focus manager reference, set by EventLoop
    public static var focusManager:FocusManager;

    public function new() {
        children = [];
        modifiers = [];
        frame = new Rect(0, 0, 0, 0);
        focusable = false;
    }

    // --- Measure / Arrange / Render / Event (override in subclasses) ---

    public function measure(constraint:Constraint):Size {
        return new Size(0, 0);
    }

    public function render(buffer:Buffer, area:Rect):Void {}

    public function handleEvent(event:Event):Bool {
        return false;
    }

    public function isFocused():Bool {
        if (focusManager == null) return false;
        return focusManager.isFocused(this);
    }

    // --- Chainable modifiers ---

    public function foregroundColor(color:Color):View {
        modifiers.push(ViewModifier.ForegroundColor(color));
        return this;
    }

    public function backgroundColor(color:Color):View {
        modifiers.push(ViewModifier.BackgroundColor(color));
        return this;
    }

    public function bold():View {
        modifiers.push(ViewModifier.Bold);
        return this;
    }

    public function dim():View {
        modifiers.push(ViewModifier.Dim);
        return this;
    }

    public function italic():View {
        modifiers.push(ViewModifier.Italic);
        return this;
    }

    public function underline():View {
        modifiers.push(ViewModifier.Underline);
        return this;
    }

    public function strikethrough():View {
        modifiers.push(ViewModifier.Strikethrough);
        return this;
    }

    public function inverse():View {
        modifiers.push(ViewModifier.Inverse);
        return this;
    }

    public function padding(?all:Int, ?top:Int, ?right:Int, ?bottom:Int, ?left:Int):View {
        if (all != null) {
            modifiers.push(ViewModifier.PaddingAll(all));
        } else {
            modifiers.push(ViewModifier.PaddingEdges(
                top != null ? top : 0,
                right != null ? right : 0,
                bottom != null ? bottom : 0,
                left != null ? left : 0
            ));
        }
        return this;
    }

    public function border(?style:BorderStyle):View {
        modifiers.push(ViewModifier.Border(style != null ? style : BorderStyle.Single));
        return this;
    }

    public function width(w:Int):View {
        modifiers.push(ViewModifier.WidthPolicy(SizePolicy.Fixed(w)));
        return this;
    }

    public function height(h:Int):View {
        modifiers.push(ViewModifier.HeightPolicy(SizePolicy.Fixed(h)));
        return this;
    }

    public function alignment(a:Alignment):View {
        modifiers.push(ViewModifier.ContentAlignment(a));
        return this;
    }

    public function hidden():View {
        modifiers.push(ViewModifier.Hidden);
        return this;
    }

    // --- Modifier helpers ---

    public function getEffectiveStyle():Style {
        var style = new Style();
        for (mod in modifiers) {
            switch (mod) {
                case ForegroundColor(c): style.fg = c;
                case BackgroundColor(c): style.bg = c;
                case Bold: style.bold = true;
                case Dim: style.dim = true;
                case Italic: style.italic = true;
                case Underline: style.underline = true;
                case Strikethrough: style.strikethrough = true;
                case Inverse: style.inverse = true;
                default:
            }
        }
        return style;
    }

    public function getPadding():Edge {
        var pad = Edge.none();
        for (mod in modifiers) {
            switch (mod) {
                case PaddingAll(v):
                    pad = Edge.all(v);
                case PaddingEdges(t, r, b, l):
                    pad = new Edge(t, r, b, l);
                default:
            }
        }
        return pad;
    }

    public function getBorderStyle():BorderStyle {
        for (mod in modifiers) {
            switch (mod) {
                case Border(s): return s;
                default:
            }
        }
        return BorderStyle.None;
    }

    /**
        Whether this view cuts its children at its own edge.

        `nui`'s `clip` modifier, which this backend named as a canonical
        decoration and then dropped: `NodeRenderer.applyModifiers` had no case
        for it and said "no terminal equivalent -- skipped on purpose". There
        is one. `ScrollView` has used it since before there was a canon:
        render into a buffer of your own, copy back only the window you own.
    **/
    public function isClipped():Bool {
        for (mod in modifiers) {
            switch (mod) {
                case Clip: return true;
                default:
            }
        }
        return false;
    }

    /**
        Draw a child, cut to `area` if that child asked to be cut.

        Every container calls this rather than `render` directly. Without it a
        child writes into the SHARED screen buffer and nothing intersects its
        writes with the rectangle it was given -- `Buffer.set` clips to the
        terminal, not to a view -- so a row too narrow for its labels drew over
        whatever stood beside it.

        The scratch buffer re-bases the child at its own origin, exactly as
        `ScrollView` does, and only the cells inside `area` are copied back.
        Allocated only for a view that asked: a buffer per child per frame
        would be a real cost in a terminal that redraws whole screens.
    **/
    public function renderInto(buffer:Buffer, area:Rect):Void {
        if (!isClipped() || area.width <= 0 || area.height <= 0) {
            render(buffer, area);
            return;
        }
        var scratch = new Buffer(area.width, area.height);
        render(scratch, new Rect(0, 0, area.width, area.height));
        for (y in 0...area.height) {
            for (x in 0...area.width) {
                var cell = scratch.get(x, y);
                buffer.set(area.x + x, area.y + y, cell.char, cell.style);
            }
        }
    }

    public function isHidden():Bool {
        for (mod in modifiers) {
            switch (mod) {
                case Hidden: return true;
                default:
            }
        }
        return false;
    }

    public function getFixedWidth():Int {
        for (mod in modifiers) {
            switch (mod) {
                case WidthPolicy(Fixed(v)): return v;
                default:
            }
        }
        return -1;
    }

    public function getFixedHeight():Int {
        for (mod in modifiers) {
            switch (mod) {
                case HeightPolicy(Fixed(v)): return v;
                default:
            }
        }
        return -1;
    }

    public function getAlignment():Alignment {
        for (mod in modifiers) {
            switch (mod) {
                case ContentAlignment(a): return a;
                default:
            }
        }
        return Alignment.Left;
    }

    // --- Helper: compute total extra space from padding + border ---

    public function getInsets():Edge {
        var pad = getPadding();
        var hasBorder = getBorderStyle() != BorderStyle.None;
        var borderInset = hasBorder ? 1 : 0;
        return new Edge(
            pad.top + borderInset,
            pad.right + borderInset,
            pad.bottom + borderInset,
            pad.left + borderInset
        );
    }
}
