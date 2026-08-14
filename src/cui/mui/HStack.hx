package cui.mui;


/**
	`cui`'s conformance for `mui.ui.HStack`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class HStack extends cui.ui.HStack {
    public function new(content:Array<cui.View>, ?spacing:Float) {
        var s = 0;
        if (spacing != null && spacing > 0) {
            s = Std.int(Math.max(1, Math.min(4, Math.ceil(spacing / 4))));
        }
        super(content, s);
    }
}
