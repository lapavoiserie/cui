package cui.mui;


/**
	`cui`'s conformance for `mui.ui.ScrollView`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class ScrollView extends cui.ui.ScrollView {
	public function new(content:Array<cui.View>, ?offset:cui.ui.ScrollView.ScrollOffset) {
		super(new cui.ui.VStack(content), offset != null ? offset : ownPosition());
	}

	/**
		A position this view keeps, for content nothing else scrolls.

		A **static state cell**, like the tab selection beside it: held in a
		local it was new on every frame, so a scroll went back to the top the
		moment anything re-rendered -- and a plain variable never marks the frame
		dirty, so the move would not have been drawn anyway.

		One scrolling page per application. A screen with two independent scroll
		views has to say which position belongs to which, and passing one is what
		that looks like.
	**/
	static var position:cui.state.State<Int> = new cui.state.State(0, "mui.scrollView.position");

	static function ownPosition():cui.ui.ScrollView.ScrollOffset {
		return new cui.ui.ScrollView.ScrollOffset(() -> position.get(), v -> position.set(v));
	}
}
