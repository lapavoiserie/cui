package cui.ui;

import cui.state.Binding;

/**
	A password field: an `Input` that never shows what it holds.

	One mark per character, so every index is still an index into the real
	value and the caret lines up. Everything else -- the caret kept across the
	rebuild typing causes, the scroll, the selection of keys -- is `Input`'s and
	is not written again.

	The value is the application's: bound, pre-filled, read back. That is the
	difference from a secret, which no application holds at all.
**/
class Password extends Input {
	public function new(binding:Binding<String>, placeholder:String = "") {
		super(binding, placeholder);
		this.masked = true;
	}
}
