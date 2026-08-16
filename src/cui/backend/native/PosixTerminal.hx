package cui.backend.native;

import cui.layout.Size;

@:headerCode('
#ifndef _WIN32
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <string.h>

static struct termios cui_orig_termios;
static bool cui_raw_mode = false;
#endif
')
class PosixTerminal {
    @:functionCode('
#ifndef _WIN32
        if (cui_raw_mode) return;
        tcgetattr(STDIN_FILENO, &cui_orig_termios);
        struct termios raw = cui_orig_termios;
        raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
        raw.c_oflag &= ~(OPOST);
        raw.c_cflag |= (CS8);
        raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
        raw.c_cc[VMIN] = 0;
        raw.c_cc[VTIME] = 0;
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
        cui_raw_mode = true;
#endif
    ')
    public static function enableRawMode():Void {}

    @:functionCode('
#ifndef _WIN32
        if (!cui_raw_mode) return;
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &cui_orig_termios);
        cui_raw_mode = false;
#endif
    ')
    public static function disableRawMode():Void {}

    @:functionCode('
#ifndef _WIN32
        struct winsize ws;
        if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1) {
            return ::cui::layout::Size_obj::__new(80, 24);
        }
        return ::cui::layout::Size_obj::__new(ws.ws_col, ws.ws_row);
#endif
        return ::cui::layout::Size_obj::__new(80, 24);
    ')
    public static function getTermSize():Size {
        return new Size(80, 24);
    }

    @:functionCode('
#ifndef _WIN32
        fd_set fds;
        struct timeval tv;
        FD_ZERO(&fds);
        FD_SET(STDIN_FILENO, &fds);
        tv.tv_sec = timeoutMs / 1000;
        tv.tv_usec = (timeoutMs % 1000) * 1000;
        int ret = select(STDIN_FILENO + 1, &fds, NULL, NULL, &tv);
        if (ret <= 0) return -1;
        unsigned char c;
        int n = read(STDIN_FILENO, &c, 1);
        if (n <= 0) return -1;
        return (int)c;
#endif
        return -1;
    ')
    public static function readByte(timeoutMs:Int):Int {
        return -1;
    }

    @:functionCode('
#ifndef _WIN32
        unsigned char c;
        int n = read(STDIN_FILENO, &c, 1);
        if (n <= 0) return -1;
        return (int)c;
#endif
        return -1;
    ')
    public static function readByteImmediate():Int {
        return -1;
    }

    // Output uses Haxe Sys for correct UTF-8 encoding
    public static function writeStdout(data:String):Void {
        Sys.print(data);
    }

    public static function flushStdout():Void {
        Sys.stdout().flush();
    }
}
