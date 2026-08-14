package cui.mui;


/**
	`cui`'s conformance for `mui.ui.TextInput`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class TextInput extends cui.ui.Input {
    public function new(placeholder:String, state:TextInputBinding) {
        // cui.ui.Input takes (binding, placeholder) — reversed order
        super(state.unwrap(), placeholder);
    }
}
