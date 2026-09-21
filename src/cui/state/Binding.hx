package cui.state;

class Binding<T> {
    var _get:Void->T;
    var _set:T->Void;

    /**
        The cell this binding was made from, when it was made from one.

        A binding is a pair of closures and says nothing about what it edits,
        which is all a control used to need. `cui.focus.FocusManager` needs
        more: "the field that edits THIS cell" is what a control is, where a
        position in the focus ring is only where it happened to sit.
    **/
    public var source(default, null):Dynamic = null;

    public function new(getFn:Void->T, setFn:T->Void) {
        _get = getFn;
        _set = setFn;
    }

    public function get():T {
        return _get();
    }

    public function set(v:T):Void {
        _set(v);
    }

    public static function from<T>(state:State<T>):Binding<T> {
        var made = new Binding(
            () -> state.get(),
            (v) -> state.set(v)
        );
        made.source = state;
        return made;
    }
}
