package cui.state;

class StateBase {
    static var dirtyFlag:Bool = false;

    public static function markDirty():Void {
        dirtyFlag = true;
    }

    public static function isDirty():Bool {
        return dirtyFlag;
    }

    public static function clearDirty():Void {
        dirtyFlag = false;
    }
}

/**
    Reactive state cell.

    The reactive half lives in `rui.state.State` — the core shared with the
    other La Pavoiserie backends — so a read inside a `rui` effect tracks it and
    a write notifies. cui itself does not use effects: it redraws from
    `StateBase`'s dirty flag, which is now raised by the platform sink rather
    than from `set()` directly. Same behaviour, one shared implementation.

    Inherited: `.get()`, `.set(v)`, `.value`, `.peek()`, `.applyExternal(v)`,
    `.setPlatformSink(sink)`, `.name`, `.dispose()`, `.toString()`.

    One deliberate change: the shared `set()` skips a write whose value is
    unchanged, so it no longer raises the dirty flag for a no-op. Every cui
    state is a scalar, so this only removes redundant redraws.
**/
class State<T> extends rui.state.State<T> {
    public function new(initialValue:T, name:String) {
        super(initialValue, name);
        setPlatformSink(_ -> StateBase.markDirty());
    }

    public function setTo(v:T):State<T> {
        set(v);
        return this;
    }
}

class IntState extends State<Int> {
    public function new(initialValue:Int, name:String) {
        super(initialValue, name);
    }

    public function inc(amount:Int = 1):Void {
        set(get() + amount);
    }

    public function dec(amount:Int = 1):Void {
        set(get() - amount);
    }
}

class BoolState extends State<Bool> {
    public function new(initialValue:Bool, name:String) {
        super(initialValue, name);
    }

    public function toggle():Void {
        set(!get());
    }
}

class FloatState extends State<Float> {
    public function new(initialValue:Float, name:String) {
        super(initialValue, name);
    }

    public function inc(amount:Float = 1.0):Void {
        set(get() + amount);
    }

    public function dec(amount:Float = 1.0):Void {
        set(get() - amount);
    }
}

class StringState extends State<String> {
    public function new(initialValue:String, name:String) {
        super(initialValue, name);
    }

    public function append(s:String):Void {
        set(get() + s);
    }

    public function clear():Void {
        set("");
    }
}
