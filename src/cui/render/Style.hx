package cui.render;

import cui.render.Color;

class Style {
    public var fg:Color;
    public var bg:Color;
    public var bold:Bool;
    public var dim:Bool;
    public var italic:Bool;
    public var underline:Bool;
    public var strikethrough:Bool;
    public var inverse:Bool;

    public function new() {
        fg = Color.Default;
        bg = Color.Default;
        bold = false;
        dim = false;
        italic = false;
        underline = false;
        strikethrough = false;
        inverse = false;
    }

    public function clone():Style {
        var s = new Style();
        s.fg = fg;
        s.bg = bg;
        s.bold = bold;
        s.dim = dim;
        s.italic = italic;
        s.underline = underline;
        s.strikethrough = strikethrough;
        s.inverse = inverse;
        return s;
    }

    public function equals(other:Style):Bool {
        if (other == null) return false;
        return colorEquals(fg, other.fg) && colorEquals(bg, other.bg)
            && bold == other.bold && dim == other.dim
            && italic == other.italic && underline == other.underline
            && strikethrough == other.strikethrough && inverse == other.inverse;
    }

    static function colorEquals(a:Color, b:Color):Bool {
        return switch [a, b] {
            case [Default, Default]: true;
            case [Named(c1), Named(c2)]: Type.enumIndex(c1) == Type.enumIndex(c2);
            case [Indexed(i1), Indexed(i2)]: i1 == i2;
            case [Rgb(r1, g1, b1), Rgb(r2, g2, b2)]: r1 == r2 && g1 == g2 && b1 == b2;
            case [Role(a), Role(b)]: a == b;
            default: false;
        };
    }

    public function toAnsi():String {
        var parts = new Array<String>();
        parts.push("\x1b[0m");

        switch (fg) {
            case Default:
            case Named(c): parts.push("\x1b[" + namedFg(c) + "m");
            // Resolved here, where the terminal's own palette applies.
            case Role(name): parts.push("\x1b[" + namedFg(cui.nui.Colors.named(name)) + "m");
            case Indexed(i): parts.push("\x1b[38;5;" + i + "m");
            case Rgb(r, g, b): parts.push("\x1b[38;2;" + r + ";" + g + ";" + b + "m");
        }

        switch (bg) {
            case Default:
            case Named(c): parts.push("\x1b[" + namedBg(c) + "m");
            case Role(name): parts.push("\x1b[" + namedBg(cui.nui.Colors.named(name)) + "m");
            case Indexed(i): parts.push("\x1b[48;5;" + i + "m");
            case Rgb(r, g, b): parts.push("\x1b[48;2;" + r + ";" + g + ";" + b + "m");
        }

        if (bold) parts.push("\x1b[1m");
        if (dim) parts.push("\x1b[2m");
        if (italic) parts.push("\x1b[3m");
        if (underline) parts.push("\x1b[4m");
        if (inverse) parts.push("\x1b[7m");
        if (strikethrough) parts.push("\x1b[9m");

        return parts.join("");
    }

    static function namedFg(c:NamedColor):Int {
        return switch (c) {
            case Black: 30;
            case Red: 31;
            case Green: 32;
            case Yellow: 33;
            case Blue: 34;
            case Magenta: 35;
            case Cyan: 36;
            case White: 37;
            case BrightBlack: 90;
            case BrightRed: 91;
            case BrightGreen: 92;
            case BrightYellow: 93;
            case BrightBlue: 94;
            case BrightMagenta: 95;
            case BrightCyan: 96;
            case BrightWhite: 97;
        };
    }

    static function namedBg(c:NamedColor):Int {
        return namedFg(c) + 10;
    }
}
