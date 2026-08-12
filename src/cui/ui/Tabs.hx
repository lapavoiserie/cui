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

typedef TabItem = {
    label:String,
    content:View,
};

class Tabs extends View {
    var tabs:Array<TabItem>;
    var activeBinding:TabSelection;

    public function new(tabs:Array<TabItem>, active:TabSelection) {
        super();
        this.tabs = tabs;
        this.activeBinding = active;
        this.focusable = true;

        // Set children to include active tab's content for focus ring traversal
        var idx = active.get();
        if (idx >= 0 && idx < tabs.length) {
            children = [tabs[idx].content];
        }
    }

    function getActiveIndex():Int {
        var idx = activeBinding.get();
        if (idx < 0) return 0;
        if (idx >= tabs.length) return tabs.length - 1;
        return idx;
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

        // Header takes 1 row + separator takes 1 row = 2
        var headerH = 2;
        var contentH = maxH - insets.verticalTotal() - headerH;

        return new Size(
            fw > 0 ? fw : maxW,
            fh > 0 ? fh : maxH
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
        var activeIdx = getActiveIndex();
        var focused = isFocused();

        // Render tab header
        var x = inner.x;
        for (i in 0...tabs.length) {
            var tab = tabs[i];
            var isActive = i == activeIdx;

            var tabStyle = style.clone();
            if (isActive) {
                tabStyle.bold = true;
                if (focused) tabStyle.inverse = true;
            } else {
                tabStyle.dim = true;
            }

            var label = " " + tab.label + " ";
            if (x + label.length > inner.x + inner.width) break;
            buffer.writeString(x, inner.y, label, tabStyle);
            x += label.length;

            // Separator between tabs
            if (i < tabs.length - 1 && x < inner.x + inner.width) {
                buffer.set(x, inner.y, "\u2502", style);
                x++;
            }
        }

        // Fill rest of header line
        for (rx in x...(inner.x + inner.width)) {
            buffer.set(rx, inner.y, " ", style);
        }

        // Draw separator line under header
        if (inner.height > 1) {
            for (sx in inner.x...(inner.x + inner.width)) {
                buffer.set(sx, inner.y + 1, "\u2500", style);
            }
        }

        // Render active tab content
        if (inner.height > 2 && activeIdx >= 0 && activeIdx < tabs.length) {
            var contentArea = new Rect(inner.x, inner.y + 2, inner.width, inner.height - 2);
            tabs[activeIdx].content.render(buffer, contentArea);
        }
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Left:
                        var idx = getActiveIndex();
                        if (idx > 0) {
                            activeBinding.set(idx - 1);
                            return true;
                        }
                    case Right:
                        var idx = getActiveIndex();
                        if (idx < tabs.length - 1) {
                            activeBinding.set(idx + 1);
                            return true;
                        }
                    default:
                }
            default:
        }

        // Then the tab showing. Its content is rendered from `tabs`, not from
        // `children`, so a walk of the tree cannot reach it -- which left a
        // scroll view inside a tab unable to hear an arrow key at all. The tabs
        // own those views, so the tabs pass the event on.
        var idx = getActiveIndex();
        if (idx >= 0 && idx < tabs.length && tabs[idx].content != null) {
            return tabs[idx].content.handleEvent(event);
        }
        return false;
    }
}

class TabSelection {
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

    public static function fromState(state:IntState):TabSelection {
        return new TabSelection(
            () -> state.get(),
            (v) -> state.set(v)
        );
    }
}
