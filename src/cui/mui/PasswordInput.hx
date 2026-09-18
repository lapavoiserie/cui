package cui.mui;


/**
	`cui`'s conformance for `mui.ui.PasswordInput`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. A terminal has one way to
	hide a value and it is the same one everywhere: a mark per character.
**/
class PasswordInput extends cui.ui.Password {
    public function new(placeholder:String, state:TextInputBinding) {
        super(state.unwrap(), placeholder);
    }
}
