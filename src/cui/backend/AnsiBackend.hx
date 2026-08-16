package cui.backend;

import cui.layout.Size;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.event.MouseEvent;
import cui.backend.native.Terminal;

class AnsiBackend implements Backend {
    var outputBuf:StringBuf;

    public function new() {
        outputBuf = new StringBuf();
    }

    public function enterRawMode():Void {
        Terminal.enableRawMode();
    }

    public function leaveRawMode():Void {
        Terminal.disableRawMode();
    }

    public function enterAlternateScreen():Void {
        Terminal.writeStdout("\x1b[?1049h");
    }

    public function leaveAlternateScreen():Void {
        Terminal.writeStdout("\x1b[?1049l");
    }

    public function hideCursor():Void {
        Terminal.writeStdout("\x1b[?25l");
    }

    public function showCursor():Void {
        Terminal.writeStdout("\x1b[?25h");
    }

    public function moveCursor(x:Int, y:Int):Void {
        Terminal.writeStdout("\x1b[" + (y + 1) + ";" + (x + 1) + "H");
    }

    public function write(data:String):Void {
        Terminal.writeStdout(data);
    }

    public function flush():Void {
        Terminal.flushStdout();
    }

    public function getSize():Size {
        return Terminal.getTermSize();
    }

    public function enableMouseCapture():Void {
        // Enable SGR mouse mode (1006) + any-event tracking (1003)
        Terminal.writeStdout("\x1b[?1000h\x1b[?1006h");
    }

    public function disableMouseCapture():Void {
        Terminal.writeStdout("\x1b[?1006l\x1b[?1000l");
    }

    public function pollEvent(timeoutMs:Int):Null<Event> {
        var byte = Terminal.readByte(timeoutMs);
        if (byte < 0) return null;
        return parseInput(byte);
    }

    function parseInput(byte:Int):Null<Event> {
        if (byte == 27) {
            return parseEscape();
        }

        // Specific control keys (must come before generic Ctrl+letter range)
        // Tab = 0x09 (would otherwise match Ctrl+I)
        if (byte == 9) {
            return Event.Key(new KeyEvent(KeyCode.Tab));
        }

        // Enter = 0x0D/0x0A (would otherwise match Ctrl+M/Ctrl+J)
        if (byte == 13 || byte == 10) {
            return Event.Key(new KeyEvent(KeyCode.Enter));
        }

        // Backspace = 0x08 or 0x7F
        if (byte == 8 || byte == 127) {
            return Event.Key(new KeyEvent(KeyCode.Backspace));
        }

        // Ctrl+letter (remaining: 1-8, 11-12, 14-26)
        if (byte >= 1 && byte <= 26) {
            var ch = String.fromCharCode(byte + 96);
            return Event.Key(new KeyEvent(KeyCode.Char(ch), true));
        }

        // Regular character
        if (byte >= 32 && byte < 127) {
            return Event.Key(new KeyEvent(KeyCode.Char(String.fromCharCode(byte))));
        }

        // UTF-8 multi-byte
        if (byte >= 128) {
            return parseUtf8(byte);
        }

        return null;
    }

    function parseEscape():Null<Event> {
        var b2 = Terminal.readByteImmediate();
        if (b2 < 0) {
            return Event.Key(new KeyEvent(KeyCode.Escape));
        }

        if (b2 == 91) { // [
            return parseCsi();
        }

        if (b2 == 79) { // O — SS3 sequences (F1-F4)
            var b3 = Terminal.readByteImmediate();
            return switch (b3) {
                case 80: Event.Key(new KeyEvent(KeyCode.F(1)));
                case 81: Event.Key(new KeyEvent(KeyCode.F(2)));
                case 82: Event.Key(new KeyEvent(KeyCode.F(3)));
                case 83: Event.Key(new KeyEvent(KeyCode.F(4)));
                default: Event.Key(new KeyEvent(KeyCode.Escape));
            };
        }

        // Alt+key
        if (b2 >= 32 && b2 < 127) {
            return Event.Key(new KeyEvent(KeyCode.Char(String.fromCharCode(b2)), false, true));
        }

        return Event.Key(new KeyEvent(KeyCode.Escape));
    }

    function parseCsi():Null<Event> {
        var b3 = Terminal.readByteImmediate();
        if (b3 < 0) return Event.Key(new KeyEvent(KeyCode.Escape));

        // SGR mouse: \x1b[< btn;col;row M/m
        if (b3 == 60) { // '<'
            return parseSgrMouse();
        }

        // Arrow keys and simple sequences
        return switch (b3) {
            case 65: Event.Key(new KeyEvent(KeyCode.Up));
            case 66: Event.Key(new KeyEvent(KeyCode.Down));
            case 67: Event.Key(new KeyEvent(KeyCode.Right));
            case 68: Event.Key(new KeyEvent(KeyCode.Left));
            case 72: Event.Key(new KeyEvent(KeyCode.Home));
            case 70: Event.Key(new KeyEvent(KeyCode.End));
            case 90: Event.Key(new KeyEvent(KeyCode.BackTab, false, false, true)); // Shift+Tab
            default:
                // Extended sequences like \x1b[1~ (Home), \x1b[3~ (Delete), etc.
                if (b3 >= 48 && b3 <= 57) {
                    parseExtendedCsi(b3);
                } else {
                    Event.Key(new KeyEvent(KeyCode.Escape));
                }
        };
    }

    function parseSgrMouse():Null<Event> {
        // Read: btn;col;row followed by M (press) or m (release)
        var params = new Array<Int>();
        var current = 0;

        while (true) {
            var b = Terminal.readByteImmediate();
            if (b < 0) return null;

            if (b >= 48 && b <= 57) {
                current = current * 10 + (b - 48);
            } else if (b == 59) { // ;
                params.push(current);
                current = 0;
            } else if (b == 77 || b == 109) { // M=press, m=release
                params.push(current);
                var isPress = (b == 77);

                if (params.length >= 3) {
                    var btnCode = params[0];
                    var col = params[1] - 1; // 1-based to 0-based
                    var row = params[2] - 1;

                    var button = switch (btnCode & 3) {
                        case 0: MouseButton.Left;
                        case 1: MouseButton.Middle;
                        case 2: MouseButton.Right;
                        default: MouseButton.None;
                    };

                    // Scroll wheel
                    if (btnCode & 64 != 0) {
                        button = (btnCode & 1 == 0) ? MouseButton.ScrollUp : MouseButton.ScrollDown;
                    }

                    var action = isPress ? MouseAction.Press : MouseAction.Release;
                    // Motion flag
                    if (btnCode & 32 != 0) {
                        action = MouseAction.Move;
                    }

                    return Event.Mouse(new MouseEvent(col, row, button, action));
                }
                return null;
            } else {
                return null; // unexpected byte, bail
            }
        }
    }

    function parseExtendedCsi(firstDigit:Int):Null<Event> {
        var num = firstDigit - 48;
        while (true) {
            var b = Terminal.readByteImmediate();
            if (b < 0) break;
            if (b >= 48 && b <= 57) {
                num = num * 10 + (b - 48);
            } else if (b == 126) { // ~
                return switch (num) {
                    case 1: Event.Key(new KeyEvent(KeyCode.Home));
                    case 2: Event.Key(new KeyEvent(KeyCode.Insert));
                    case 3: Event.Key(new KeyEvent(KeyCode.Delete));
                    case 4: Event.Key(new KeyEvent(KeyCode.End));
                    case 5: Event.Key(new KeyEvent(KeyCode.PageUp));
                    case 6: Event.Key(new KeyEvent(KeyCode.PageDown));
                    case 15: Event.Key(new KeyEvent(KeyCode.F(5)));
                    case 17: Event.Key(new KeyEvent(KeyCode.F(6)));
                    case 18: Event.Key(new KeyEvent(KeyCode.F(7)));
                    case 19: Event.Key(new KeyEvent(KeyCode.F(8)));
                    case 20: Event.Key(new KeyEvent(KeyCode.F(9)));
                    case 21: Event.Key(new KeyEvent(KeyCode.F(10)));
                    case 23: Event.Key(new KeyEvent(KeyCode.F(11)));
                    case 24: Event.Key(new KeyEvent(KeyCode.F(12)));
                    default: null;
                };
            } else {
                break;
            }
        }
        return null;
    }

    function parseUtf8(firstByte:Int):Null<Event> {
        var bytes = [firstByte];
        var remaining = 0;
        if ((firstByte & 0xE0) == 0xC0) remaining = 1;
        else if ((firstByte & 0xF0) == 0xE0) remaining = 2;
        else if ((firstByte & 0xF8) == 0xF0) remaining = 3;

        for (i in 0...remaining) {
            var b = Terminal.readByteImmediate();
            if (b < 0) return null;
            bytes.push(b);
        }

        // Decode UTF-8 to codepoint
        var cp = 0;
        if (remaining == 1) {
            cp = ((bytes[0] & 0x1F) << 6) | (bytes[1] & 0x3F);
        } else if (remaining == 2) {
            cp = ((bytes[0] & 0x0F) << 12) | ((bytes[1] & 0x3F) << 6) | (bytes[2] & 0x3F);
        } else if (remaining == 3) {
            cp = ((bytes[0] & 0x07) << 18) | ((bytes[1] & 0x3F) << 12) | ((bytes[2] & 0x3F) << 6) | (bytes[3] & 0x3F);
        }

        var char = String.fromCharCode(cp);
        return Event.Key(new KeyEvent(KeyCode.Char(char)));
    }
}
