package cui.render;

enum NamedColor {
    Black;
    Red;
    Green;
    Yellow;
    Blue;
    Magenta;
    Cyan;
    White;
    BrightBlack;
    BrightRed;
    BrightGreen;
    BrightYellow;
    BrightBlue;
    BrightMagenta;
    BrightCyan;
    BrightWhite;
}

enum Color {
    Default;
    Named(c:NamedColor);
    Indexed(index:Int);
    Rgb(r:Int, g:Int, b:Int);

    /**
        What a colour is FOR, kept as the word until something draws it.

        A role crosses as a role (`nui.Role`) and is resolved by whoever paints
        it — here, one of the sixteen, so it follows whatever palette the person
        set in their terminal. That is the point rather than a compromise: a
        `danger` drawn in the terminal's own red is more right than a `#DC2626`
        chosen on somebody else's machine.

        Kept as the word rather than resolved on arrival so that a role
        **survives being described again**. A tree relayed through a terminal
        that flattened it would reach the far end carrying a number, with
        nothing left to say it had ever been a role.
    **/
    Role(name:String);
}
