package cui.focus;

import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;

class FocusManager {
    public var focusIndex:Int;
    var focusableViews:Array<View>;

    /**
        What the focused control edits, remembered across rebuilds.

        The ring is rebuilt from scratch on every frame and the focus was an
        INDEX into it, clamped with a modulo. So the focus teleported the
        moment the number of focusable views above it changed -- `pui`'s docs
        have cited this as the thing not to do since the day its own focus was
        written -- and with it the caret and the draft, which `Input` keyed by
        the same slot.

        A control that edits a cell is that cell's control. When the ring is
        rebuilt the focus goes to the view editing the same cell, wherever it
        sits now; only a control that edits nothing (a `Button`) is still
        followed by position, and that is all a position can honestly do.
    **/
    var focusedCell:Dynamic = null;

    /** The key of the focused control, for one that edits no cell. **/
    var focusedKey:Null<String> = null;

    public function new() {
        focusIndex = 0;
        focusableViews = [];
    }

    public function buildFocusRing(root:View):Void {
        focusableViews = [];
        collectFocusable(root);
        // The cell first: the control that edits what the focused one edited.
        if (focusedCell != null) {
            for (i in 0...focusableViews.length) {
                if (focusableViews[i].focusIdentity() == focusedCell) {
                    focusIndex = i;
                    return;
                }
            }
        }
        // Then its key. A control that edits nothing -- a button in a list
        // that sorts -- has no cell to be found by, and was found by position:
        // the focus stayed on the slot while the button moved out of it.
        if (focusedKey != null) {
            for (i in 0...focusableViews.length) {
                if (focusableViews[i].key == focusedKey) {
                    focusIndex = i;
                    return;
                }
            }
        }
        // Clamp focusIndex if views changed
        if (focusableViews.length > 0) {
            focusIndex = focusIndex % focusableViews.length;
        } else {
            focusIndex = 0;
        }
        remember();
    }

    /** Note what the focused control edits, for the next rebuild. **/
    function remember():Void {
        var view = currentFocus();
        focusedCell = view == null ? null : view.focusIdentity();
        focusedKey = view == null ? null : view.key;
    }

    function collectFocusable(view:View):Void {
        if (view.focusable) {
            focusableViews.push(view);
        }
        for (child in view.children) {
            collectFocusable(child);
        }
    }

    public function focusNext():Void {
        if (focusableViews.length == 0) return;
        focusIndex = (focusIndex + 1) % focusableViews.length;
        remember();
    }

    public function focusPrevious():Void {
        if (focusableViews.length == 0) return;
        focusIndex = (focusIndex - 1 + focusableViews.length) % focusableViews.length;
        remember();
    }

    public function currentFocus():Null<View> {
        if (focusableViews.length == 0) return null;
        if (focusIndex < 0 || focusIndex >= focusableViews.length) return null;
        return focusableViews[focusIndex];
    }

    public function isFocused(view:View):Bool {
        return currentFocus() == view;
    }

    public function count():Int {
        return focusableViews.length;
    }

    public function focusView(view:View):Void {
        for (i in 0...focusableViews.length) {
            if (focusableViews[i] == view) {
                focusIndex = i;
                remember();
                return;
            }
        }
    }

    public function handleNavigation(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Tab:
                        focusNext();
                        return true;
                    case BackTab:
                        focusPrevious();
                        return true;
                    default:
                }
            default:
        }
        return false;
    }

    public function dispatchToFocused(event:Event):Bool {
        var focused = currentFocus();
        if (focused == null) return false;
        return focused.handleEvent(event);
    }
}
