package cui.state;

/**
	What a text field takes: a `Binding<String>`, or the cell itself.

	`Binding` is a class, so it cannot declare an implicit cast; a field
	therefore took a binding and nothing else, and `mui`'s markup -- which
	binds the CELL, because that is what a view written by hand binds -- could
	not reach one. `<TextInput text={name_}/>` failed to compile with
	*cui.state.StringState should be cui.state.Binding<String>*, on a backend
	that declares the tag and draws it.

	An abstract in front of the class says the same thing without moving
	anything: a binding passes through untouched, and a cell is wrapped where
	it is written rather than at every call site. `pui.ui.TextInputBinding` is
	the same shape for the same reason.
**/
abstract TextBinding(Binding<String>) from Binding<String> to Binding<String> {
	@:from static inline function fromState(state:State<String>):TextBinding
		return Binding.from(state);
}
