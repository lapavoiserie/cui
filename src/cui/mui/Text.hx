package cui.mui;

import mui.ui.TextScale;
import mui.ui.TextStyle;

/**
	`cui`'s conformance for `mui.ui.Text`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class Text extends cui.ui.Text {
    public function new(content:String, ?scale:TextScale, ?style:TextStyle) {
        super(content);
        // A terminal cell is one size, so "bigger" can only be rendered as
        // heavier. The two heading steps are bold and the two others are not,
        // which is the whole of what this scale can honestly mean here.
        styled(scale == null ? null : Std.string(scale).toLowerCase(),
            style == null || style.family == null ? null : (style.family : String),
            style == null ? null : style.weight,
            style == null ? null : style.italic,
            style != null && style.numbers == mui.ui.Numbers.Tabular);
    }
}
