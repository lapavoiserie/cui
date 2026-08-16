package cui.backend;

/**
	Which backend an application gets.

	There is one, and there is expected to stay one. `AnsiBackend` speaks escape
	sequences, and every system `cui` targets understands them — Windows since
	the console learned to, which is what `cui.backend.native.WindowsTerminal`
	turns on. What differs between systems is raw mode, terminal size and byte
	reading, and that is dispatched a layer down by
	`cui.backend.native.Terminal`.

	This class stays because it is the seam: a terminal that does **not** speak
	ANSI would be a second `Backend`, not a second `Terminal`, and it would be
	chosen here.
**/
class CrossTerminal {
	public static function create():Backend {
		return new AnsiBackend();
	}
}
