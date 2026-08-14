package cui.mui;

import mui.ui.TabItem;

/**
	`cui`'s conformance for `mui.ui.TabView`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
class TabView extends cui.ui.Tabs {
    /**
        The selection is optional here, as it is absent everywhere else.

        `cui` asks the application which tab is active, because a terminal has
        no widget keeping that for you. The other three backends keep it
        themselves, so requiring it here gave `mui.ui.TabView` two signatures --
        and an example whose whole claim is one source could not use it.

        Passing one stays possible, and is what you want when something else
        drives the selection. Leaving it out gets a selection this view owns.
    **/
    public function new(tabs:Array<TabItem>, ?active:cui.ui.Tabs.TabSelection) {
        super([for (t in tabs) {label: t.label, content: t.content}],
            active != null ? active : ownSelection());
    }

    /**
        A selection this view keeps, for tabs nothing else drives.

        A **static state cell**, for two reasons found the hard way. It has to
        outlive a rebuild: held in a local, it was new on every frame and the
        selection snapped back to the first tab as soon as anything re-rendered.
        And a plain variable tells the loop nothing -- a cell marks the frame
        dirty when it changes, which is what makes the new tab appear.

        One tab bar per application, said rather than discovered, as on the
        three other backends that own their selection.
    **/
    static var selection:cui.state.State<Int> = new cui.state.State(0, "mui.tabView.selection");

    static function ownSelection():cui.ui.Tabs.TabSelection {
        return new cui.ui.Tabs.TabSelection(() -> selection.get(), i -> selection.set(i));
    }
}
