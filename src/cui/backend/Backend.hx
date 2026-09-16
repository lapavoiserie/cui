package cui.backend;

import cui.layout.Size;
import cui.event.Event;

interface Backend {
    function enterRawMode():Void;
    function leaveRawMode():Void;
    function enterAlternateScreen():Void;
    function leaveAlternateScreen():Void;
    function hideCursor():Void;
    function showCursor():Void;
    function moveCursor(x:Int, y:Int):Void;
    function write(data:String):Void;
    function flush():Void;
    function getSize():Size;
    function pollEvent(timeoutMs:Int):Null<Event>;

    /**
        One byte of input, raw, or -1 when none came in time.

        For reading a terminal's answer to a question -- what it can draw, how
        big a cell is (`cui.term.Graphics`) -- which is bytes, not an event.
    **/
    function readByte(timeoutMs:Int):Int;
    function enableMouseCapture():Void;
    function disableMouseCapture():Void;
}
