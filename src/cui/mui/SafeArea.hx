package cui.mui;


/**
	`cui`'s conformance for `mui.ui.SafeArea`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
@:muiSupport("none", "a terminal has no safe area")
class SafeArea extends cui.ui.VStack {
    public function new(content:Array<cui.View>) {
        super(content, 0);
        // One cell. A terminal's margin is measured in characters, and a
        // desktop's 24 pixels would be a quarter of the screen here -- which is
        // exactly why the number is decided per backend rather than passed in.
        padding(1);
    }

    public function safeArea():cui.View {
        return this;
    }
}
