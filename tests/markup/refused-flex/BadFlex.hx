import mui.macros.Markup.ui;

/** `flex` on cui: no stack reads a weight, so markup must refuse it by name. **/
class BadFlex {
	static function main() {
		var s = ui(<VStack><Text text="grows" flex={2.0}/></VStack>);
	}
}
