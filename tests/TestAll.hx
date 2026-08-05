import cui.layout.Size;
import cui.layout.Rect;
import cui.layout.Edge;
import cui.layout.Constraint;
import cui.render.Color;
import cui.render.Style;
import cui.render.Cell;
import cui.render.Buffer;
import cui.render.BorderStyle;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.HStack;
import cui.ui.Spacer;
import cui.ui.Box;
import cui.state.State;
import cui.nui.ViewSource;
import cui.nui.NodeRenderer;
import nui.PropValue;
import cui.View;

class TestAll {
    static var passed = 0;
    static var failed = 0;

    static function assert(condition:Bool, msg:String):Void {
        if (condition) {
            passed++;
        } else {
            failed++;
            Sys.println('  FAIL: $msg');
        }
    }

    static function section(name:String):Void {
        Sys.println('[$name]');
    }

    // --- Layout tests ---

    static function testSize():Void {
        section("Size");
        var s = new Size(10, 20);
        assert(s.width == 10, "width");
        assert(s.height == 20, "height");
        assert(s.equals(new Size(10, 20)), "equals");
        assert(!s.equals(new Size(10, 21)), "not equals");
    }

    static function testRect():Void {
        section("Rect");
        var r = new Rect(5, 10, 20, 15);
        assert(r.contains(5, 10), "contains top-left");
        assert(r.contains(24, 24), "contains bottom-right");
        assert(!r.contains(4, 10), "not contains left");
        assert(!r.contains(25, 10), "not contains right");

        var inner = r.inner(new Edge(1, 2, 3, 4));
        assert(inner.x == 9, "inner x");
        assert(inner.y == 11, "inner y");
        assert(inner.width == 14, "inner width");
        assert(inner.height == 11, "inner height");
    }

    static function testEdge():Void {
        section("Edge");
        var e = Edge.all(5);
        assert(e.horizontalTotal() == 10, "horizontal total");
        assert(e.verticalTotal() == 10, "vertical total");

        var sym = Edge.symmetric(2, 3);
        assert(sym.top == 2, "symmetric top");
        assert(sym.left == 3, "symmetric left");
    }

    // --- Render tests ---

    static function testStyle():Void {
        section("Style");
        var s1 = new Style();
        var s2 = new Style();
        assert(s1.equals(s2), "default styles equal");

        s1.bold = true;
        assert(!s1.equals(s2), "bold not equal");

        var s3 = s1.clone();
        assert(s1.equals(s3), "clone equals");
        s3.italic = true;
        assert(!s1.equals(s3), "clone independent");
    }

    static function testCell():Void {
        section("Cell");
        var c1 = new Cell("A", new Style());
        var c2 = new Cell("A", new Style());
        assert(c1.equals(c2), "same cells equal");

        c2.char = "B";
        assert(!c1.equals(c2), "different char not equal");
    }

    static function testBuffer():Void {
        section("Buffer");
        var buf = new Buffer(10, 5);
        assert(buf.width == 10, "width");
        assert(buf.height == 5, "height");

        // Default cells are spaces
        assert(buf.get(0, 0).char == " ", "default space");

        // Set and get
        var style = new Style();
        buf.set(3, 2, "X", style);
        assert(buf.get(3, 2).char == "X", "set/get");

        // Out of bounds returns default
        assert(buf.get(-1, 0).char == " ", "out of bounds");
        assert(buf.get(100, 0).char == " ", "out of bounds right");

        // writeString
        buf.writeString(0, 0, "Hello", style);
        assert(buf.get(0, 0).char == "H", "writeString H");
        assert(buf.get(4, 0).char == "o", "writeString o");

        // fill
        buf.fill(new Rect(0, 0, 3, 2), "#", style);
        assert(buf.get(0, 0).char == "#", "fill 0,0");
        assert(buf.get(2, 1).char == "#", "fill 2,1");
        assert(buf.get(3, 0).char == "l", "fill boundary");
    }

    // --- View measure tests ---

    static function testTextMeasure():Void {
        section("Text.measure");
        var t = new Text("Hello");
        var s = t.measure(Constraint.Unbounded);
        assert(s.width == 5, "unbounded width = text length");
        assert(s.height == 1, "unbounded height = 1");

        // With border
        var t2 = new Text("Hi");
        t2.border(Single);
        var s2 = t2.measure(Constraint.Unbounded);
        assert(s2.width == 4, "bordered width = 2 + 2");
        assert(s2.height == 3, "bordered height = 1 + 2");
    }

    static function testVStackMeasure():Void {
        section("VStack.measure");
        var vs = new VStack([
            new Text("Line 1"),
            new Text("Line 2"),
            new Text("Line 3"),
        ], 0);
        var s = vs.measure(Constraint.AtMost(80, 24));
        assert(s.height == 3, "3 lines = height 3");
    }

    static function testHStackMeasure():Void {
        section("HStack.measure");
        var hs = new HStack([
            new Text("A"),
            new Text("BB"),
            new Text("CCC"),
        ], 1);
        var s = hs.measure(Constraint.AtMost(80, 24));
        assert(s.width == 8, "1+2+3 + 2 spacing = 8");
        assert(s.height == 1, "height = 1");
    }

    static function testSpacerInVStack():Void {
        section("Spacer in VStack");
        var vs = new VStack([
            new Text("Top"),
            new Spacer(),
            new Text("Bottom"),
        ], 0);
        // Render into a buffer and check positions
        var buf = new Buffer(20, 10);
        vs.render(buf, new Rect(0, 0, 20, 10));
        assert(buf.get(0, 0).char == "T", "Top at y=0");
        assert(buf.get(0, 9).char == "B", "Bottom at y=9");
    }

    static function testSpacerInHStack():Void {
        section("Spacer in HStack");
        var hs = new HStack([
            new Text("L"),
            new Spacer(),
            new Text("R"),
        ], 0);
        var buf = new Buffer(20, 1);
        hs.render(buf, new Rect(0, 0, 20, 1));
        assert(buf.get(0, 0).char == "L", "Left at x=0");
        assert(buf.get(19, 0).char == "R", "Right at x=19");
    }

    // --- View render tests ---

    static function testTextRender():Void {
        section("Text.render");
        var t = new Text("Hi").bold();
        var buf = new Buffer(10, 1);
        t.render(buf, new Rect(0, 0, 10, 1));
        assert(buf.get(0, 0).char == "H", "char H");
        assert(buf.get(1, 0).char == "i", "char i");
        assert(buf.get(0, 0).style.bold, "bold style");
    }

    static function testBoxBorder():Void {
        section("Box.border");
        var b = new Box(new Text("X")).border(Ascii);
        var buf = new Buffer(5, 3);
        b.render(buf, new Rect(0, 0, 5, 3));
        assert(buf.get(0, 0).char == "+", "top-left corner");
        assert(buf.get(1, 0).char == "-", "top edge");
        assert(buf.get(0, 1).char == "|", "left edge");
        assert(buf.get(1, 1).char == "X", "content");
    }

    // --- State tests ---
    // State is backed by rui.state.State; cui redraws from the dirty flag,
    // which the platform sink raises. These cover the contract the UI relies on.

    static function testState():Void {
        section("State");
        var s = new State<Int>(1, "s");
        assert(s.get() == 1, "initial value");
        assert(s.name == "s", "name");

        StateBase.clearDirty();
        s.set(2);
        assert(s.get() == 2, "set writes");
        assert(StateBase.isDirty(), "set marks dirty");

        StateBase.clearDirty();
        s.set(2);
        assert(!StateBase.isDirty(), "unchanged write does not mark dirty");

        s.value = 3;
        assert(s.value == 3, "value property reads and writes");

        assert(s.setTo(4) == s, "setTo returns the state");
        assert(s.peek() == 4, "peek reads");

        // A write coming from the platform reaches the value without raising
        // the dirty flag -- the platform already reflects it.
        StateBase.clearDirty();
        s.applyExternal(5);
        assert(s.get() == 5, "applyExternal writes");
        assert(!StateBase.isDirty(), "applyExternal does not mark dirty");

        assert(Std.string(s) == "5", "toString");
    }

    static function testTypedStates():Void {
        section("Typed states");
        var i = new IntState(0, "i");
        i.inc();
        i.inc(4);
        assert(i.get() == 5, "IntState.inc");
        i.dec(2);
        assert(i.get() == 3, "IntState.dec");

        var b = new BoolState(false, "b");
        b.toggle();
        assert(b.get() == true, "BoolState.toggle");

        var f = new FloatState(1.5, "f");
        f.inc(0.5);
        assert(f.get() == 2.0, "FloatState.inc");

        var str = new StringState("a", "str");
        str.append("b");
        assert(str.get() == "ab", "StringState.append");
        str.clear();
        assert(str.get() == "", "StringState.clear");

        StateBase.clearDirty();
        i.inc();
        assert(StateBase.isDirty(), "typed state marks dirty");
    }

    // --- nui pull contract (Phase B / B3) ---
    // Proves a consumer that knows nothing about cui can walk its tree.

    static function testNuiSource():Void {
        section("nui — pull contract");

        var pressed = 0;
        var btn = new cui.ui.Button("Ajouter", () -> pressed++);
        var stack = new VStack([new Text("Bonjour"), btn], 2);
        stack.modifiers.push(cui.modifiers.ViewModifier.PaddingAll(4));
        stack.modifiers.push(cui.modifiers.ViewModifier.Border(cui.render.BorderStyle.Single));

        var src = new ViewSource(stack);

        assert(src.typeOf(src.root()) == "VStack", "typeOf");
        assert(src.childCount(src.root()) == 2, "childCount");
        assert(src.typeOf(src.childAt(src.root(), 0)) == "Text", "childAt");
        assert(src.keyOf(src.root()) == null, "keyOf is null: cui has no identity");

        assert(src.stringProp(src.childAt(src.root(), 0), "text") == "Bonjour", "text is a plain property");
        assert(src.intProp(src.root(), "spacing") == 2, "typed int property");
        assert(src.stringProp(src.root(), "label") == "", "absent property is empty");
        assert(!src.hasProp(src.root(), "label"), "hasProp");
        assert(src.boolProp(src.childAt(src.root(), 1), "focusable"), "typed bool property");

        assert(src.modifierCount(src.root()) == 2, "modifier chain length");
        assert(src.modifierType(src.root(), 0) == "padding", "modifier type");
        assert(src.modifierFloat(src.root(), 0, 0) == 4.0, "modifier float param");
        assert(src.modifierType(src.root(), 1) == "border", "modifier order preserved");

        var id = src.actionId(src.childAt(src.root(), 1));
        assert(id >= 0, "action has an id");
        assert(src.actionId(src.root()) == -1, "no action means -1");
        src.invokeActionId(id);
        assert(pressed == 1, "action runs through its id, never a closure");

        // Un consommateur générique : ne connaît que le contrat.
        assert(dump(src, src.root()) == "VStack[padding,border](Text,Button)", "generic walk");
    }

    static function dump(src:ViewSource, n:cui.View):String {
        var s = src.typeOf(n);
        if (src.modifierCount(n) > 0) {
            var mods = [];
            for (i in 0...src.modifierCount(n)) mods.push(src.modifierType(n, i));
            s += "[" + mods.join(",") + "]";
        }
        if (src.childCount(n) > 0) {
            var kids = [];
            for (i in 0...src.childCount(n)) kids.push(dump(src, src.childAt(n, i)));
            s += "(" + kids.join(",") + ")";
        }
        return s;
    }

    // --- nui -> cui : rendre un arbre étranger (Phase B / B5) ---

    static function testNuiRenderer():Void {
        section("nui -> cui");

        var pressed = 0;
        var tree = new nui.Node("VStack")
            .child(new nui.Node("Text").prop("text", nui.PropValue.PString("Salut")))
            .child(new nui.Node("Button")
                .prop("label", nui.PropValue.PString("OK"))
                .prop("onClick", nui.PropValue.PCallback(() -> pressed++)));
        tree.modifier({type: "padding", floats: [1]});

        var view = NodeRenderer.build(tree);
        assert(Std.isOfType(view, VStack), "VStack construit depuis un nui.Node");
        assert(view.children.length == 2, "enfants construits");
        assert(Std.isOfType(view.children[0], Text), "Text construit");
        assert(view.modifiers.length == 1, "modificateur transposé");

        // Il rend vraiment : on dessine dans un buffer et on relit les cellules.
        var buf = new Buffer(20, 4);
        view.render(buf, new Rect(0, 0, 20, 4));
        // padding:1 sur la racine décale d'une colonne et d'une ligne — on lit large.
        var line = "";
        for (x in 0...10) line += buf.get(x, 1).char;
        assert(StringTools.trim(line) == "Salut", "l'arbre étranger est dessiné (\"" + line + "\")");
        assert(buf.get(0, 1).char == " ", "le padding du modificateur est appliqué");

        // Un type inconnu se voit au lieu de disparaître.
        var odd = NodeRenderer.build(new nui.Node("Hologramme"));
        var b2 = new Buffer(12, 1);
        odd.render(b2, new Rect(0, 0, 12, 1));
        assert(b2.get(0, 0).char == "?", "un type inconnu s'affiche");

        // Aller-retour : décrire, puis reconstruire depuis la description.
        var src = new ViewSource(view);
        assert(src.typeOf(src.root()) == "VStack", "aller-retour: type conservé");
        assert(src.stringProp(src.childAt(src.root(), 0), "text") == "Salut", "aller-retour: texte conservé");
    }

    // --- Main ---

    static function main():Void {
        Sys.println("CUI Test Suite\n");

        testSize();
        testRect();
        testEdge();
        testStyle();
        testCell();
        testBuffer();
        testTextMeasure();
        testVStackMeasure();
        testHStackMeasure();
        testSpacerInVStack();
        testSpacerInHStack();
        testTextRender();
        testBoxBorder();
        testState();
        testTypedStates();
        testNuiSource();
        testNuiRenderer();

        Sys.println('\n$passed passed, $failed failed');
        if (failed > 0) Sys.exit(1);
    }
}
