package cui.render;

import cui.backend.Backend;

class Renderer {
    public static function render(prev:Buffer, curr:Buffer, backend:Backend):Void {
        var output = new StringBuf();
        var lastStyle:Style = null;

        for (y in 0...curr.height) {
            for (x in 0...curr.width) {
                var prevCell = prev.get(x, y);
                var currCell = curr.get(x, y);

                // The second half of a wide character is not written: the
                // terminal is already past it, and a space there would paint
                // over the half it belongs to.
                if (currCell.continuation) continue;

                if (!currCell.equals(prevCell)) {
                    // Move cursor
                    output.add("\x1b[");
                    output.add(Std.string(y + 1));
                    output.add(";");
                    output.add(Std.string(x + 1));
                    output.add("H");

                    // Emit style if changed
                    if (lastStyle == null || !currCell.style.equals(lastStyle)) {
                        output.add(currCell.style.toAnsi());
                        lastStyle = currCell.style;
                    }

                    output.add(currCell.char);
                }
            }
        }

        // Reset style at end
        output.add("\x1b[0m");

        output.add(pictures(curr));

        var str = output.toString();
        if (str.length > 4) { // more than just the reset
            backend.write(str);
            backend.flush();
        }
    }

    /**
        The pictures of a frame, each at its cell.

        After the text, and every frame rather than only when something
        changed: a terminal owns those pixels and may have scrolled, cleared or
        reflowed them, and none of that reaches the cell diff. Nothing is
        written for a frame with no picture in it, which is almost every frame
        of almost every application.
    **/
    static function pictures(buffer:Buffer):String {
        if (buffer.graphics.length == 0) return "";
        var out = new StringBuf();
        for (picture in buffer.graphics) {
            out.add("\x1b[");
            out.add(Std.string(picture.y + 1));
            out.add(";");
            out.add(Std.string(picture.x + 1));
            out.add("H");
            out.add(picture.payload);
        }
        // The cursor is wherever the picture left it.
        out.add("\x1b[H");
        return out.toString();
    }

    public static function renderFull(buffer:Buffer, backend:Backend):Void {
        var output = new StringBuf();
        var lastStyle:Style = null;

        for (y in 0...buffer.height) {
            // Position cursor at start of each row to avoid wrapping issues
            output.add("\x1b[");
            output.add(Std.string(y + 1));
            output.add(";1H");

            for (x in 0...buffer.width) {
                var cell = buffer.get(x, y);
                if (cell.continuation) continue;
                if (lastStyle == null || !cell.style.equals(lastStyle)) {
                    output.add(cell.style.toAnsi());
                    lastStyle = cell.style;
                }
                output.add(cell.char);
            }
        }

        output.add("\x1b[0m");
        output.add(pictures(buffer));
        backend.write(output.toString());
        backend.flush();
    }
}
