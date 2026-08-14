package cui.mui;

/**
	`cui`'s conformance for `mui.state.StateAction`.

	Moved here from the `#if (mui_backend == "cui")` branch it used to live in.
	`mui` resolves it by name through `mui.Contract`, and lists it as optional
	because the six backends genuinely disagree about which of these exist.
**/
// cui uses direct state method calls instead of declarative StateActions.
// Use state.set()/state.get() with closures for cross-backend compatibility.
enum StateAction {
    Increment(state:Dynamic, amount:Int);
    Decrement(state:Dynamic, amount:Int);
    SetValue(state:Dynamic, value:Dynamic);
    Toggle(state:Dynamic);
    Append(state:Dynamic, value:Dynamic);
}
