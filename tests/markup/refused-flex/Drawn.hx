import mui.macros.Markup.ui;

/** What cui now draws: width, height and opacity reach the view. **/
class Drawn {
	static function main() {
		var t:cui.View = ui(<Text text="t" width={12.0} height={3.0} opacity={0.5}/>);
		var gone:cui.View = ui(<Text text="g" opacity={0.0}/>);
		Sys.println("fixed " + t.getFixedWidth() + "x" + t.getFixedHeight()
			+ " dim " + (t.modifiers.indexOf(Dim) >= 0) + " hidden " + gone.isHidden());
	}
}
