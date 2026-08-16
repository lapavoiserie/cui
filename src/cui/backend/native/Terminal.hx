package cui.backend.native;

import cui.layout.Size;

/**
	The six things a terminal has to do, on whichever system this is running on.

	`AnsiBackend` speaks one protocol — escape sequences — and it is the same
	protocol on all three systems. What differs is entirely underneath: how raw
	mode is entered, how the size is asked for, how a byte is waited for. Those
	six primitives are what this dispatches, and nothing above it knows there was
	a choice.

	## Why the choice is made at run time

	The obvious answer is `#if windows`, and it is wrong twice over.

	It does not work: Haxe defines no such thing. Compiling the same file on
	macOS and on Windows and printing which branch was taken gives "not defined"
	on both — so the Windows branch would never have been compiled, on Windows,
	and the failure would have been a POSIX terminal that does not build rather
	than anything pointing at the cause.

	And it would be the wrong shape even if it worked. A compile-time switch
	answers for the machine doing the **compiling**, which is the same machine
	only until someone cross-compiles.

	So the branch that has to be resolved before compiling — *which* system's
	headers exist — is left to the **C preprocessor**, which genuinely knows:
	each implementation guards its own native code with `_WIN32`, and both
	compile everywhere, one of them to empty bodies. The branch that only matters
	at run time is taken at run time, by asking the system it is running on.

	The cost is a boolean test per call, against a system call. It is not
	measurable, and it buys a binary that is correct wherever it is run.
**/
class Terminal {
	/**
		Decided once.

		`Sys.systemName()` rather than a define: this is a fact about the machine
		executing, and the only honest time to ask is while executing.
	**/
	static final windows:Bool = Sys.systemName() == "Windows";

	public static inline function enableRawMode():Void {
		if (windows) WindowsTerminal.enableRawMode() else PosixTerminal.enableRawMode();
	}

	public static inline function disableRawMode():Void {
		if (windows) WindowsTerminal.disableRawMode() else PosixTerminal.disableRawMode();
	}

	public static inline function getTermSize():Size {
		return windows ? WindowsTerminal.getTermSize() : PosixTerminal.getTermSize();
	}

	public static inline function readByte(timeoutMs:Int):Int {
		return windows ? WindowsTerminal.readByte(timeoutMs) : PosixTerminal.readByte(timeoutMs);
	}

	public static inline function readByteImmediate():Int {
		return windows ? WindowsTerminal.readByteImmediate() : PosixTerminal.readByteImmediate();
	}

	public static inline function writeStdout(data:String):Void {
		if (windows) WindowsTerminal.writeStdout(data) else PosixTerminal.writeStdout(data);
	}

	public static inline function flushStdout():Void {
		if (windows) WindowsTerminal.flushStdout() else PosixTerminal.flushStdout();
	}
}
