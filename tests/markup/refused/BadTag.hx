import mui.macros.Markup.ui;

/** A tag no cui control declares. Refused at compile time, not drawn as "?". **/
class BadTag {
	static function main() {
		var t = ui(<Hologramme/>);
	}
}
