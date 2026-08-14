package cui.mui;


/**
	`cui`'s conformance for `mui.ui.ConditionalView`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
// cui has no ConditionalView — implement at runtime
@:muiSupport("built", "cui has no conditional view: the branch is chosen at construction")
class ConditionalView extends cui.View {
    var condition:cui.state.State<Bool>;
    var thenView:cui.View;
    var elseView:Null<cui.View>;

    public function new(condition:cui.state.State<Bool>, thenView:cui.View, ?elseView:cui.View) {
        super();
        this.condition = condition;
        this.thenView = thenView;
        this.elseView = elseView;
        children = condition.get() ? [thenView] : (elseView != null ? [elseView] : []);
    }

    override public function measure(constraint:cui.layout.Constraint):cui.layout.Size {
        var active = condition.get() ? thenView : elseView;
        if (active != null) return active.measure(constraint);
        return new cui.layout.Size(0, 0);
    }

    override public function render(buffer:cui.render.Buffer, area:cui.layout.Rect):Void {
        var active = condition.get() ? thenView : elseView;
        if (active != null) active.render(buffer, area);
    }
}
