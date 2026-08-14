package cui.mui;


/**
	`cui`'s conformance for `mui.ui.ToggleBinding`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
abstract ToggleBinding(cui.ui.Checkbox.CheckboxBinding) {
    public inline function new(v:cui.ui.Checkbox.CheckboxBinding) this = v;

    @:from static inline function fromBoolState(s:cui.state.State.BoolState):ToggleBinding
        return new ToggleBinding(cui.ui.Checkbox.CheckboxBinding.fromState(s));

    @:from static inline function fromState(s:cui.state.State<Bool>):ToggleBinding
        return new ToggleBinding(new cui.ui.Checkbox.CheckboxBinding(
            () -> s.get(),
            (v) -> s.set(v)
        ));

    public inline function unwrap():cui.ui.Checkbox.CheckboxBinding return this;
}
