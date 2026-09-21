import mui.macros.Markup.ui;

/**
	What cui draws: width, height and opacity reach the view.

	The lengths are POINTS, as everywhere in the canon: 96 x 48 points is
	12 x 3 cells here. See `cui.nui.Units`.
**/
class Drawn {
	static function main() {
		var t:cui.View = ui(<Text text="t" width={96.0} height={48.0} opacity={0.5}/>);
		var gone:cui.View = ui(<Text text="g" opacity={0.0}/>);
		Sys.println("fixed " + t.getFixedWidth() + "x" + t.getFixedHeight()
			+ " dim " + (t.modifiers.indexOf(Dim) >= 0) + " hidden " + gone.isHidden());
	}
}
