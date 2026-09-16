package cui.render;

class Cell {
    public var char:String;
    public var style:Style;

    /**
        This cell belongs to the character in the cell before it.

        A terminal advances two cells for a wide character -- an emoji, a CJK
        ideograph -- so the cell after one is not a cell anybody may write: the
        terminal is already past it. `Renderer` writes nothing for these, and
        the layout above reserves them so nothing else claims the room.
    **/
    public var continuation:Bool;

    public function new(?char:String, ?style:Style) {
        this.char = char != null ? char : " ";
        this.style = style != null ? style : new Style();
        this.continuation = false;
    }

    public function equals(other:Cell):Bool {
        if (other == null) return false;
        return char == other.char && continuation == other.continuation && style.equals(other.style);
    }

    public function copyFrom(other:Cell):Void {
        char = other.char;
        style = other.style;
        continuation = other.continuation;
    }
}
