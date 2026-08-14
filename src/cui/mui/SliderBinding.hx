package cui.mui;


/**
	`cui`'s conformance for `mui.ui.SliderBinding`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
abstract SliderBinding(cui.ui.Slider.SliderBinding) {
    public inline function new(v:cui.ui.Slider.SliderBinding) this = v;

    @:from static inline function fromFloatState(s:cui.state.State.FloatState):SliderBinding
        return new SliderBinding(cui.ui.Slider.SliderBinding.fromState(s));

    @:from static inline function fromState(s:cui.state.State<Float>):SliderBinding
        return new SliderBinding(new cui.ui.Slider.SliderBinding(
            () -> s.get(),
            (v) -> s.set(v)
        ));

    public inline function unwrap():cui.ui.Slider.SliderBinding return this;
}
