package cui.backend.native;

import cui.layout.Size;

/**
	The Windows console, spoken to as if it were a terminal.

	`cui` renders with ANSI escape sequences and nothing else. That looks like it
	should rule Windows out, and for twenty years it did — but a console since
	Windows 10 1511 understands the same sequences once asked to, and since
	1809 it can hand back key presses as sequences too. So the whole of
	`AnsiBackend` — the drawing, the escape codes, the input parser — is reused
	unchanged, and only these six primitives differ.

	That is why this file exists rather than a `WindowsBackend`: the protocol is
	the same, the plumbing is not.

	## Two modes to turn on, and they are separate

	`ENABLE_VIRTUAL_TERMINAL_PROCESSING` on the **output** handle makes the
	console interpret `\x1b[…` instead of printing it. `ENABLE_VIRTUAL_TERMINAL_INPUT`
	on the **input** handle makes it deliver arrow keys and the like as escape
	sequences rather than as key records. Both are needed and neither implies the
	other; enabling only the first gives a screen that draws correctly and never
	responds.

	Both are saved and restored, because a console mode outlives the process that
	changed it: leaving raw mode set would leave the user's shell without echo.

	## The input buffer holds more than keys

	`ReadFile` on a console input handle returns the translated bytes, but the
	handle is signalled for **every** record — a window resize, a focus change,
	a menu command produce no bytes at all. Waiting on the handle and then
	reading would block on exactly those. So the records are peeked first and the
	silent ones discarded, which is what makes a resize not freeze the
	application.

	## UTF-8

	The output code page is set to UTF-8, because `writeStdout` goes through
	`Sys.print` and Haxe strings arrive as UTF-8. Without it a box-drawing
	character becomes two pieces of mojibake — the frame is the first thing
	anyone notices.
**/
@:headerCode('
#ifdef _WIN32
#include <windows.h>

static HANDLE cui_win_in = INVALID_HANDLE_VALUE;
static HANDLE cui_win_out = INVALID_HANDLE_VALUE;
static DWORD cui_win_in_mode = 0;
static DWORD cui_win_out_mode = 0;
static UINT cui_win_out_cp = 0;
static bool cui_win_raw = false;

// Discard the records that produce no bytes, so a later ReadFile cannot block
// on them. Returns false when the buffer holds nothing readable.
static bool cui_win_drain() {
	for (;;) {
		INPUT_RECORD record;
		DWORD available = 0;
		if (!PeekConsoleInputW(cui_win_in, &record, 1, &available) || available == 0)
			return false;
		bool silent =
			record.EventType == FOCUS_EVENT ||
			record.EventType == MENU_EVENT ||
			record.EventType == WINDOW_BUFFER_SIZE_EVENT ||
			(record.EventType == KEY_EVENT && !record.Event.KeyEvent.bKeyDown);
		if (!silent) return true;
		ReadConsoleInputW(cui_win_in, &record, 1, &available);
	}
}
#endif
')
class WindowsTerminal {
	@:functionCode('
#ifdef _WIN32
		if (cui_win_raw) return;
		cui_win_in = GetStdHandle(STD_INPUT_HANDLE);
		cui_win_out = GetStdHandle(STD_OUTPUT_HANDLE);
		if (cui_win_in == INVALID_HANDLE_VALUE || cui_win_out == INVALID_HANDLE_VALUE) return;

		GetConsoleMode(cui_win_in, &cui_win_in_mode);
		GetConsoleMode(cui_win_out, &cui_win_out_mode);
		cui_win_out_cp = GetConsoleOutputCP();

		DWORD out_mode = cui_win_out_mode
			| ENABLE_PROCESSED_OUTPUT
			| ENABLE_VIRTUAL_TERMINAL_PROCESSING
			| DISABLE_NEWLINE_AUTO_RETURN;
		SetConsoleMode(cui_win_out, out_mode);

		// ENABLE_PROCESSED_INPUT off is what stops Ctrl+C from raising a signal,
		// matching ISIG being cleared on the POSIX side: the application decides
		// what Ctrl+C means.
		DWORD in_mode = cui_win_in_mode;
		in_mode &= ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT
			| ENABLE_QUICK_EDIT_MODE);
		in_mode |= ENABLE_VIRTUAL_TERMINAL_INPUT | ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS;
		SetConsoleMode(cui_win_in, in_mode);

		SetConsoleOutputCP(CP_UTF8);
		cui_win_raw = true;
#endif
	')
	public static function enableRawMode():Void {}

	@:functionCode('
#ifdef _WIN32
		if (!cui_win_raw) return;
		SetConsoleMode(cui_win_in, cui_win_in_mode);
		SetConsoleMode(cui_win_out, cui_win_out_mode);
		if (cui_win_out_cp != 0) SetConsoleOutputCP(cui_win_out_cp);
		cui_win_raw = false;
#endif
	')
	public static function disableRawMode():Void {}

	@:functionCode('
#ifdef _WIN32
		CONSOLE_SCREEN_BUFFER_INFO info;
		HANDLE out = cui_win_out != INVALID_HANDLE_VALUE
			? cui_win_out : GetStdHandle(STD_OUTPUT_HANDLE);
		if (out != INVALID_HANDLE_VALUE && GetConsoleScreenBufferInfo(out, &info)) {
			// The *window*, not the buffer: a console buffer is usually far taller
			// than what is on screen, and drawing to the buffer height would put
			// most of the interface where nobody can see it.
			int columns = info.srWindow.Right - info.srWindow.Left + 1;
			int rows = info.srWindow.Bottom - info.srWindow.Top + 1;
			if (columns > 0 && rows > 0)
				return ::cui::layout::Size_obj::__new(columns, rows);
		}
#endif
		// Reached when this file is compiled for a system that is not Windows,
		// where every body above is preprocessed away. `@:functionCode` replaces
		// the Haxe body outright, so without a return here the generated C++
		// would not compile at all on macOS or Linux.
		return ::cui::layout::Size_obj::__new(80, 24);
	')
	public static function getTermSize():Size {
		return new Size(80, 24);
	}

	@:functionCode('
#ifdef _WIN32
		if (cui_win_in == INVALID_HANDLE_VALUE) return -1;
		DWORD deadline = GetTickCount() + (DWORD)(timeoutMs < 0 ? 0 : timeoutMs);
		for (;;) {
			if (cui_win_drain()) break;
			DWORD now = GetTickCount();
			if (now >= deadline) return -1;
			if (WaitForSingleObject(cui_win_in, deadline - now) != WAIT_OBJECT_0) return -1;
		}
		char c;
		DWORD read = 0;
		if (!ReadFile(cui_win_in, &c, 1, &read, NULL) || read == 0) return -1;
		return (int)(unsigned char)c;
#endif
		return -1;
	')
	public static function readByte(timeoutMs:Int):Int {
		return -1;
	}

	@:functionCode('
#ifdef _WIN32
		if (cui_win_in == INVALID_HANDLE_VALUE) return -1;
		// No wait at all: this is the continuation of an escape sequence whose
		// first byte has already arrived, so anything still coming is already in
		// the buffer. Blocking here on a lone ESC is what makes a terminal feel
		// stuck for a second on every press.
		if (!cui_win_drain()) return -1;
		char c;
		DWORD read = 0;
		if (!ReadFile(cui_win_in, &c, 1, &read, NULL) || read == 0) return -1;
		return (int)(unsigned char)c;
#endif
		return -1;
	')
	public static function readByteImmediate():Int {
		return -1;
	}

	/** Output goes through Haxe, which encodes UTF-8 — the console is set to match. **/
	public static function writeStdout(data:String):Void {
		Sys.print(data);
	}

	public static function flushStdout():Void {
		Sys.stdout().flush();
	}
}
