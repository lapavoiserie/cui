package cui.mui;

import mui.ui.TextScale;

/**
	`cui`'s conformance for `mui.ui.Text`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class Text extends cui.ui.Text {
    public function new(content:String, ?scale:TextScale) {
        super(content);
        // A terminal cell is one size, so "bigger" can only be rendered as
        // heavier. The two heading steps are bold and the two others are not,
        // which is the whole of what this scale can honestly mean here.
        if (scale != null) switch (scale) {
            case Title | Subtitle: bold();
            case Body | Caption:
        }
    }
}
