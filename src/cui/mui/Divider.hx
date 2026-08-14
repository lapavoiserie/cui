package cui.mui;


/**
	`cui`'s conformance for `mui.ui.Divider`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class Divider extends cui.ui.Divider {
    public function new() {
        super(true);
    }
}
