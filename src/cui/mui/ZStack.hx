package cui.mui;


/**
	`cui`'s conformance for `mui.ui.ZStack`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
// Terminal can't overlay views — fall back to VStack
@:muiSupport("approx", "a terminal cannot overlay: the views are stacked instead")
class ZStack extends cui.ui.VStack {
    public function new(content:Array<cui.View>) {
        super(content, 0);
    }
}
