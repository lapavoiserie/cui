package cui.ui;

import cui.View;

/**
	One tab: a title, and the page behind it when it is the chosen one.

	The canon's shape, and `pui.ui.Tab` is the reference. **Only the selected
	tab carries its page**, as its single child; the others are empty. That is
	what keeps a snapshot one picture, lets a tap anywhere else change the tab,
	and makes the secret guarantee structural -- a `SecretInput` in a tab nobody
	chose is not in the tree at all.

	`cui.ui.Tabs` used to take a `{label, content}` typedef instead, which is
	why a canonical `Tabs` could not be built here: a typedef is not a node, so
	there was nothing for the declaration reader to see.
**/
@:node("Tab")
@:content("page")
class Tab extends View {
	/** The title shown in the bar. **/
	@:prop public var label:String;

	/**
		A glyph shown before the title, named from `nui.Icons`.

		Drawn rather than only carried: a name this terminal does not know is
		left out, exactly as `cui.ui.Button` leaves one out.
	**/
	@:prop public var icon:Null<String> = null;

	public function new(label:String, ?page:View) {
		super();
		this.label = label == null ? "" : label;
		if (page != null) children = [page];
	}

	/** The page this tab holds, or null when it is not the chosen one. **/
	public var page(get, never):Null<View>;

	function get_page():Null<View>
		return children != null && children.length > 0 ? children[0] : null;
}
