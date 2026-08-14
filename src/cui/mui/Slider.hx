package cui.mui;


/**
	`cui`'s conformance for `mui.ui.Slider`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class Slider extends cui.ui.Slider {
    public function new(state:SliderBinding, min:Float = 0.0, max:Float = 1.0) {
        super(state.unwrap(), min, max);
    }
}
