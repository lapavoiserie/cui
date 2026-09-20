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

/**
    A tab bar and the page under it.

    Its children are `Tab`s and **only the chosen one carries its page** --
    the canon's rule, and `pui.ui.Tabs` says at length why that one rule does
    three jobs. This took a `{label, content}` typedef before, which is why a
    canonical `Tabs` could not be built here at all: a typedef is not a node,
    so the declaration reader had nothing to see and `SilicaSink`'s cousin
    here simply did not know the type.

    `Tabs.of(...)` keeps the old shape for code that had it.
**/
@:node("Tabs")
@:content("content")
class Tabs extends View {
    /** Which tab is open, and where a tap on another one goes. **/
    @:prop("selectedIndex", "onSelect") public var active:TabSelection;

    public function new(content:Array<View>, active:TabSelection) {
        super();
        this.children = content == null ? [] : content;
        this.active = active;
        this.focusable = true;
    }

    /** The old `{label, content}` shape, for code written against it. **/
    public static function of(items:Array<TabItem>, active:TabSelection):Tabs {
        var chosen = active.get();
        return new Tabs([
            for (i in 0...items.length)
                new cui.ui.Tab(items[i].label, i == chosen ? items[i].content : null)
        ], active);
    }

    /**
        Its `Tab` children, in order.

        Written `cui.ui.Tab` in full, and that is not style: `KeyCode` has a
        `Tab` constructor -- the key -- and an unqualified `Tab` in this module
        resolves to it. `Std.isOfType(c, Tab)` then takes an enum constructor
        where a class was meant, compiles without a word, and answers false for
        every child. The bar came out blank.
    **/
    var tabs(get, never):Array<cui.ui.Tab>;

    function get_tabs():Array<cui.ui.Tab>
        return [for (c in children) if (Std.isOfType(c, cui.ui.Tab)) cast(c, cui.ui.Tab)];

    function getActiveIndex():Int {
        var idx = active.get();
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

            // Cut, not dropped. A tab that did not fit used to end the loop,
            // so it and every tab after it vanished -- a person could not see
            // that a section existed at all. `pui` shortens the title and
            // keeps the tab, and the two backends should not disagree about
            // what a narrow bar means.
            var edge = inner.x + inner.width;
            if (x >= edge) break;

            // The icon a `Tab` named, drawn before its title. Declared and not
            // drawn is the defect this backend family keeps finding; a name
            // this terminal does not know is left out, as `Button` leaves one
            // out, rather than showing a box.
            var glyph = tab.icon == null ? null : cui.nui.Icons.glyphOf(tab.icon);
            var label = " " + (glyph == null ? "" : glyph + " ") + tab.label + " ";
            x += buffer.writeString(x, inner.y, label, tabStyle, edge);

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
            // Only the chosen tab carries a page; the others are empty.
            var page = tabs[activeIdx].page;
            if (page != null) page.renderInto(buffer, contentArea);
        }
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Left:
                        var idx = getActiveIndex();
                        if (idx > 0) {
                            active.set(idx - 1);
                            return true;
                        }
                    case Right:
                        var idx = getActiveIndex();
                        if (idx < tabs.length - 1) {
                            active.set(idx + 1);
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
        if (idx >= 0 && idx < tabs.length && tabs[idx].page != null) {
            return tabs[idx].page.handleEvent(event);
        }
        return false;
    }
}

/**
	Which tab is open: the same two functions a `Picker`'s selection is, and
	now literally the same type.

	They were two identical classes -- get an Int, set an Int -- and
	`cui.nui.Cells.intCell` can only build one of them, so a canonical `Tabs`
	could not be constructed from a node at all while they were separate. One
	shape, one type.
**/
typedef TabSelection = cui.ui.Picker.PickerBinding;
