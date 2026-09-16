package cui.mui;


/**
	`cui`'s conformance for `mui.ui.Picker`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`.

	A terminal has no z-order, so this one cycles rather than dropping down —
	`cui.ui.Picker` says why. The contract is the index and the options, and
	those are the same everywhere.
**/
@:muiSupport("approx", "a terminal cannot overlay: the options cycle on one row")
class Picker extends cui.ui.Picker {
    public function new(label:String, options:Array<String>, state:PickerBinding) {
        super(label, options, state.unwrap());
    }
}
