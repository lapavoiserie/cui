package cui.mui;


/**
	`cui`'s conformance for `mui.ui.TextInputBinding`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
abstract TextInputBinding(cui.state.Binding<String>) {
    public inline function new(v:cui.state.Binding<String>) this = v;

    @:from static inline function fromStringState(s:cui.state.State.StringState):TextInputBinding
        return new TextInputBinding(cui.state.Binding.from(s));

    @:from static inline function fromState(s:cui.state.State<String>):TextInputBinding
        return new TextInputBinding(cui.state.Binding.from(s));

    public inline function unwrap():cui.state.Binding<String> return this;
}
