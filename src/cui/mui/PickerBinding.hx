package cui.mui;


/**
	`cui`'s conformance for `mui.ui.PickerBinding`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. The same shape as
	`SliderBinding`, over the index of the option chosen.
**/
abstract PickerBinding(cui.ui.Picker.PickerBinding) {
    public inline function new(v:cui.ui.Picker.PickerBinding) this = v;

    @:from static inline function fromIntState(s:cui.state.State.IntState):PickerBinding
        return new PickerBinding(cui.ui.Picker.PickerBinding.fromState(s));

    @:from static inline function fromState(s:cui.state.State<Int>):PickerBinding
        return new PickerBinding(new cui.ui.Picker.PickerBinding(
            () -> s.get(),
            (v) -> s.set(v)
        ));

    public inline function unwrap():cui.ui.Picker.PickerBinding return this;
}
