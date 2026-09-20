package cui.nui;

/**
	A binding made out of what a node carried and where its writes go.

	The one step in building a control from a node that a declaration cannot
	describe: what cell a two-way control takes is the backend's own idea.
	`cui`'s is a get/set pair closed over the received value — there is no cell
	behind it, because the value belongs to whoever sent the tree and this side
	only reports.

	`pui` answers the same question with a `pui.state.State` whose platform sink
	reports. What they share is only the question, which is what
	`nui.macros.Derive` asks: here is what arrived, here is where writes go.
**/
class Cells {
	public static function boolCell(value:Bool, tell:Bool->Void):cui.ui.Checkbox.CheckboxBinding
		return new cui.ui.Checkbox.CheckboxBinding(() -> value, v -> tell(v));

	public static function intCell(value:Int, tell:Int->Void):cui.ui.Picker.PickerBinding
		return new cui.ui.Picker.PickerBinding(() -> value, v -> tell(v));

	public static function floatCell(value:Float, tell:Float->Void):cui.ui.Slider.SliderBinding
		return new cui.ui.Slider.SliderBinding(() -> value, v -> tell(v));

	public static function stringCell(value:String, tell:String->Void):cui.state.Binding<String>
		return new cui.state.Binding(() -> value, v -> tell(v));

	/**
		The same four, told where the control was written.

		`nui.macros.Construct` hands a markup element's place to every
		backend, because a factory that takes it on one and not on another is
		two shapes of the same question. This backend keeps nothing under it:
		its cell is an ordinary object, collected when the view that held it
		is. `aui` is the one that needs it -- its cells live in a registry and
		a fresh one per rebuild would grow that map for good.
	**/
	public static function boolCellAt(site:String, value:Bool, tell:Bool->Void)
		return boolCell(value, tell);

	public static function intCellAt(site:String, value:Int, tell:Int->Void)
		return intCell(value, tell);

	public static function floatCellAt(site:String, value:Float, tell:Float->Void)
		return floatCell(value, tell);

	public static function stringCellAt(site:String, value:String, tell:String->Void)
		return stringCell(value, tell);
}
