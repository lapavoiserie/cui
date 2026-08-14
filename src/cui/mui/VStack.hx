package cui.mui;


/**
	`cui`'s conformance for `mui.ui.VStack`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class VStack extends cui.ui.VStack {
    public function new(content:Array<cui.View>, ?spacing:Float) {
        // GUI spacing is in pixels; terminal spacing is in rows.
        // Scale down: 1-7 → 1 row, 8+ → 1 row per 8px, capped at 2.
        var s = 0;
        if (spacing != null && spacing > 0) {
            s = Std.int(Math.max(1, Math.min(2, Math.ceil(spacing / 8))));
        }
        super(content, s);
    }
}
