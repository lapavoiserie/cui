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

class State<T> {
    var _value:T;
    var _name:String;

    public var name(get, never):String;

    function get_name():String {
        return _name;
    }

    public function new(initialValue:T, name:String) {
        _value = initialValue;
        _name = name;
    }

    public function get():T {
        return _value;
    }

    public function set(v:T):Void {
        _value = v;
        StateBase.markDirty();
    }

    public function setTo(v:T):State<T> {
        set(v);
        return this;
    }

    public function toString():String {
        return Std.string(_value);
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
