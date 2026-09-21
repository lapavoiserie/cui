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

    /**
        The canon's `clip`: children cut at this view's edge.

        `cui.nui.NodeRenderer` used to drop it, saying "no terminal
        equivalent -- skipped on purpose". There is one, and `ScrollView` has
        used it since before there was a canon: render into a buffer of your
        own and copy back only the window you own.

        Without it a child writes straight into the shared screen buffer, which
        clips to the TERMINAL and not to a view, so a row too narrow for its
        labels drew over whatever stood beside it.
    **/
    static function testClip():Void {
        section("Clip");

        // A child that genuinely overdraws. cui's own views do not -- a `Text`
        // wraps to the width it is given -- so using one would have proved
        // something about `Text` and nothing about clipping, and would have
        // passed either way.
        function draw(clipped:Bool):Buffer {
            var box = new HStack([new Overdrawer()], 0);
            if (clipped) box.modifiers.push(cui.modifiers.ViewModifier.Clip);
            var buf = new Buffer(12, 1);
            for (x in 0...12) buf.set(x, 0, ".", new cui.render.Style());
            box.renderInto(buf, new Rect(0, 0, 4, 1));
            return buf;
        }

        var loose = draw(false);
        assert(loose.get(5, 0).char == "F",
            "a child that overdraws reaches past the box it was given");

        var cut = draw(true);
        assert(cut.get(0, 0).char == "A", "clipped, what fits is still drawn");
        assert(cut.get(5, 0).char == ".", "and what does not fit no longer reaches the neighbour");

        // A fact about the tree, not about this layout: it crosses back out.
        var view = new HStack([new Text("x")], 0);
        view.modifiers.push(cui.modifiers.ViewModifier.Clip);
        var said = cui.nui.Describe.describe(view);
        var types = [for (m in said.modifiers) m.type];
        assert(types.indexOf(nui.Modifiers.CLIP) >= 0, "and clip is described by its canonical name");

        // And comes back in.
        var built = cui.nui.NodeRenderer.build(new nui.Node("HStack")
            .modifier({type: nui.Modifiers.CLIP}));
        assert(built.isClipped(), "a received clip reaches the view");
    }

    /**
        A control too narrow cuts its OWN content at its OWN edge.

        `Buffer.writeString` stops at the terminal's edge, not at the box a
        control was given, and nothing here passed a narrower one. So a picker,
        a button or a tab bar wider than its box wrote straight over whatever
        stood beside it -- the same defect `pui` had inside `Tabs` and the
        segmented `Picker`, found at the image in the Farceur window.

        The tab bar also changes policy rather than only gaining a bound: a tab
        that did not fit used to END the loop, so it and every tab after it
        vanished and a person could not see that a section existed. It is cut
        now, as `pui` cuts it. The two backends should not disagree about what
        a narrow bar means.
    **/
    static function testControlsCut():Void {
        section("Controls cut their own content");

        // A marker to the right of each control, standing for a neighbour.
        function fresh(width:Int):Buffer {
            var buf = new Buffer(width, 3);
            for (y in 0...3) for (x in 0...width) buf.set(x, y, ".", new cui.render.Style());
            return buf;
        }

        var picker = new cui.ui.Picker("Scène", ["Aperçu · Replay", "Programme · Titre"],
            new cui.ui.Picker.PickerBinding(() -> 0, v -> {}));
        var buf = fresh(30);
        picker.render(buf, new Rect(0, 0, 10, 1));
        assert(buf.get(11, 0).char == ".", "a picker narrower than its content stops at its own edge");

        var button = new cui.ui.Button("Démarrer la diffusion", () -> {});
        buf = fresh(30);
        button.render(buf, new Rect(0, 0, 8, 1));
        assert(buf.get(9, 0).char == ".", "and so does a button whose label is longer than it is");

        // Cut, not dropped: the fourth tab's first letters are still there.
        var tabs = new cui.ui.Tabs([
            new cui.ui.Tab("Source", new cui.ui.Text("")),
            new cui.ui.Tab("Transitions"),
        ], new cui.ui.Tabs.TabSelection(() -> 0, v -> {}));
        buf = fresh(30);
        tabs.render(buf, new Rect(0, 0, 12, 3));
        assert(buf.get(13, 0).char == ".", "a tab bar stops at its own edge");
        var bar = "";
        for (x in 0...12) bar += buf.get(x, 0).char;

        // " Source │ Tr": the second tab is cut to what fits. It used to end
        // the loop, leaving " Source │" and blank to the edge.
        // The canon's shape, both ways: a received `Tabs` builds one, and a
        // built one describes as `Tabs` with `Tab` children carrying titles --
        // which is what flattening it to a VStack used to throw away.
        var received = cui.nui.NodeRenderer.build(new nui.Node("Tabs")
            .prop("selectedIndex", nui.PropValue.PInt(1))
            .child(new nui.Node("Tab").prop("label", nui.PropValue.PString("Source")))
            .child(new nui.Node("Tab").prop("label", nui.PropValue.PString("Diffusion"))));
        assert(Std.isOfType(received, cui.ui.Tabs), "a received Tabs builds a Tabs");

        var said = cui.nui.Describe.describe(tabs);
        assert(said.type == "Tabs" && said.children.length == 2
            && said.children[0].type == "Tab",
            "and a Tabs describes as Tabs with Tab children");
        assert(nui.PropValue.PropValueTools.asString(
            said.children[1].props.get("label")) == "Transitions",
            "whose titles cross: flattening to a VStack lost exactly those");

        assert(bar.indexOf("Tr") >= 0,
            "and the tab that does not fit is cut rather than dropped, as pui cuts it");
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
        // 16 points: one row and two columns here. It said `1` while the
        // canon's lengths were read as cells -- see `cui.nui.Units`.
        tree.modifier({type: "padding", floats: [16]});

        var view = NodeRenderer.build(tree);
        assert(Std.isOfType(view, VStack), "VStack construit depuis un nui.Node");
        assert(view.children.length == 2, "enfants construits");
        assert(Std.isOfType(view.children[0], Text), "Text construit");
        assert(view.modifiers.length == 1, "modificateur transposé");

        // Il rend vraiment : on dessine dans un buffer et on relit les cellules.
        var buf = new Buffer(20, 4);
        view.render(buf, new Rect(0, 0, 20, 4));
        // padding sur la racine décale d'une ligne et de deux colonnes — on lit large.
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

    // --- Icons and pictures ---

    static function testIconsAndPictures():Void {
        section("Icons and pictures");

        var missing = [for (n in nui.Icons.NAMES) if (cui.nui.Icons.glyphOf(n) == null) n];
        assert(missing.length == 0, "every name of the vocabulary has a character: " + missing);
        assert(Lambda.count(cui.nui.Icons.GLYPHS) == nui.Icons.NAMES.length, "and nothing else has one");
        // Every -off name now has a character of its own; the stroke stays for
        // an application whose own table needs it, and for a name that one day
        // has no crossed-out picture to use.
        var stroked = 0;
        for (name in ["mic-off", "eye-off", "speaker-off"]) {
            var base = name.substr(0, name.length - 4);
            if (cui.nui.Icons.glyphOf(name) == cui.nui.Icons.glyphOf(base) + cui.nui.Icons.STROKE) stroked++;
            assert(cui.nui.Icons.glyphOf(name) != cui.nui.Icons.glyphOf(base), name + " is not its base undrawn");
        }
        assert(stroked == 0, "every -off name has a character of its own");

        // The stroke itself still belongs to the cell before it, whoever uses it.
        var buf = new Buffer(6, 1);
        buf.writeString(0, 0, "\u266a" + cui.nui.Icons.STROKE + "x", new Style());
        assert(buf.get(0, 0).char == "\u266a" + cui.nui.Icons.STROKE && buf.get(1, 0).char == "x",
            "a stroked character is one cell, not two");

        var icon = new cui.ui.Icon("mic-off");
        assert(icon.measure(Unbounded).width == 2, "and a picture asks for the two it is drawn in");
        icon.render(buf, new Rect(0, 0, 6, 1));
        assert(buf.get(0, 0).char == cui.nui.Icons.glyphOf("mic-off"), "the cell holding the whole character");

        var newer = new cui.ui.Icon("teleport", "Teleport");
        assert(newer.display() == "Teleport", "a name with no character is its label");
        assert(new cui.ui.Icon("teleport").display() == "teleport", "or the name, spoken");

        var picture = new cui.ui.Image("asset:logo.png", "Farceur", {width: 120});
        assert(picture.display() == "[Farceur]", "a picture is its alt, in brackets");
        assert(new cui.ui.Image("asset:logo.png").display() == "[picture]", "and says so when it has none");
        var pbuf = new Buffer(12, 1);
        picture.render(pbuf, new Rect(0, 0, 12, 1));
        assert(pbuf.get(0, 0).char == "[" && pbuf.get(1, 0).char == "F", "drawn where it stands");

        var take = new cui.ui.Button("TAKE", () -> {}, "swap");
        var iconCells = cui.nui.Icons.cellsOf("swap");
        assert(take.measure(Unbounded).width == 4 + iconCells + 1 + 4, "a button with an icon leaves room for it");
        var bbuf = new Buffer(20, 1);
        take.render(bbuf, new Rect(0, 0, 20, 1));
        assert(bbuf.get(2, 0).char == cui.nui.Icons.glyphOf("swap") && bbuf.get(2 + iconCells + 1, 0).char == "T",
            "the character comes before the label, with the room it asks for between them");
        assert(new cui.ui.Button("Cut", () -> {}, "cut").icon == null, "a name outside the vocabulary is no icon");

        // --- The wire ---
        var described = cui.nui.Describe.describe(new VStack([
            new cui.ui.Image("asset:logo.png", "Farceur", {width: 120, fit: "cover"}),
            new cui.ui.Icon("mic-off", "Muted"),
            new cui.ui.Button("TAKE", () -> {}, "swap")
        ]));
        var img = described.children[0];
        assert(img.type == "Image" && nui.PropValue.PropValueTools.asString(img.props.get("src")) == "asset:logo.png"
            && nui.PropValue.PropValueTools.asString(img.props.get("alt")) == "Farceur"
            && nui.PropValue.PropValueTools.asFloat(img.props.get("width")) == 120
            && nui.PropValue.PropValueTools.asString(img.props.get("fit")) == "cover", "a picture crosses as src, alt, width and fit");
        assert(described.children[1].type == "Icon"
            && nui.PropValue.PropValueTools.asString(described.children[1].props.get("name")) == "mic-off"
            && nui.PropValue.PropValueTools.asString(described.children[1].props.get("label")) == "Muted", "an icon as its name and label");
        assert(nui.PropValue.PropValueTools.asString(described.children[2].props.get("icon")) == "swap", "a button carries its icon");

        var built = NodeRenderer.build(new nui.Node("VStack")
            .child(new nui.Node("Image").prop("src", PString("asset:x.png")).prop("alt", PString("x")))
            .child(new nui.Node("Icon").prop("name", PString("star")))
            .child(new nui.Node("Button").prop("label", PString("Go")).prop("icon", PString("forward"))));
        var kids:Array<View> = built.children;
        assert(Std.isOfType(kids[0], cui.ui.Image) && (cast kids[0] : cui.ui.Image).alt == "x", "a received picture is one");
        assert(Std.isOfType(kids[1], cui.ui.Icon) && (cast kids[1] : cui.ui.Icon).name == "star", "a received icon is one");
        assert((cast kids[2] : cui.ui.Button).icon == "forward", "a received button keeps its icon");
    }

    // --- How a text is set ---

    static function testTextStyle():Void {
        section("Text styling");

        var heading = new cui.ui.Text("Sources").styled("title");
        var counter = new cui.ui.Text("00:12:34").styled("body", "Inter", 700, true, true);
        var plain = new cui.ui.Text("plain");

        // What a terminal can draw, it draws: a cell is one size, so a heading
        // is heavier rather than larger.
        var buf = new Buffer(20, 1);
        heading.render(buf, new Rect(0, 0, 20, 1));
        assert(buf.get(0, 0).style.bold, "a heading is bold, a cell being one size");
        var counterCells = new Buffer(20, 1);
        counter.render(counterCells, new Rect(0, 0, 20, 1));
        assert(counterCells.get(0, 0).style.bold && counterCells.get(0, 0).style.italic,
            "a weight past six hundred is bold, and italic is italic");
        var plainCells = new Buffer(20, 1);
        plain.render(plainCells, new Rect(0, 0, 20, 1));
        assert(!plainCells.get(0, 0).style.bold, "and text that said nothing is neither");

        // What it cannot draw, it carries: a described tree says what it was
        // given, whatever this screen can show of it.
        var described = cui.nui.Describe.describe(new VStack([heading, counter]));
        var first = described.children[0];
        var second = described.children[1];
        assert(nui.PropValue.PropValueTools.asString(first.props.get("scale")) == "title",
            "a heading crosses as a heading");
        assert(nui.PropValue.PropValueTools.asString(second.props.get("family")) == "Inter"
            && nui.PropValue.PropValueTools.asInt(second.props.get("weight")) == 700
            && nui.PropValue.PropValueTools.asBool(second.props.get("italic"))
            && nui.PropValue.PropValueTools.asString(second.props.get("numbers")) == "tabular",
            "and a family a terminal has no use for crosses with the rest");

        var built = NodeRenderer.build(new nui.Node("VStack")
            .child(new nui.Node("Text").prop("text", PString("Sources")).prop("scale", PString("subtitle")))
            .child(new nui.Node("Text").prop("text", PString("plain"))));
        var kids:Array<View> = built.children;
        var receivedHeading = new Buffer(20, 1);
        kids[0].render(receivedHeading, new Rect(0, 0, 20, 1));
        assert(receivedHeading.get(0, 0).style.bold, "a received heading is set as one, which it was not before the canon");
        var receivedPlain = new Buffer(20, 1);
        kids[1].render(receivedPlain, new Rect(0, 0, 20, 1));
        assert(!receivedPlain.get(0, 0).style.bold, "and received running text is left alone");
    }

    // --- Pictures in a terminal ---

    /** The 4x3 picture of `tests/`: primary colours, one transparent pixel. **/
    static inline var PNG_RGBA = "iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAYAAAC09K7GAAAALklEQVR4nGP4z8DwHwwZ/oMAAxMjA0gESjAy/GfiEpFjOJlq1MjIzMLw+9dvBgDd1BEQRpizSgAAAABJRU5ErkJggg==";

    /** The same picture as greys, to check a second colour type. **/
    static inline var PNG_GREY = "iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAAAAACRn/EaAAAAF0lEQVR4nGPwmSb7n5Hh0cVtDEI1TL8AK/UF8+IN+eAAAAAASUVORK5CYII=";

    static function testPictures():Void {
        section("Pictures");

        // --- PNG ---
        var px = cui.render.Png.decode(haxe.crypto.Base64.decode(PNG_RGBA));
        assert(px != null && px.width == 4 && px.height == 3, "a PNG decodes to its own size");
        assert(px.red(0, 0) == 255 && px.green(0, 0) == 0 && px.blue(0, 0) == 0, "the first pixel is the red it was written as");
        assert(px.alpha(3, 0) == 0, "and a transparent pixel keeps its alpha");
        assert(px.red(1, 2) == 200 && px.green(1, 2) == 100 && px.blue(1, 2) == 50, "a pixel on the last row too");
        var grey = cui.render.Png.decode(haxe.crypto.Base64.decode(PNG_GREY));
        assert(grey != null && grey.red(0, 0) == grey.blue(0, 0) && grey.red(0, 0) == 76, "a greyscale PNG decodes to greys");
        assert(cui.render.Png.decode(haxe.io.Bytes.ofString("not a picture at all")) == null, "and what is not a PNG decodes to nothing");

        // Over a background: a terminal cell has no transparency.
        var flat = px.over(0, 0, 0);
        assert(flat.red(3, 0) == 0 && flat.alpha(3, 0) == 255, "a transparent pixel takes the colour behind it");

        // --- Half blocks: a cell is two pixels ---
        var buffer = new Buffer(4, 1);
        cui.render.Blocks.draw(buffer, new Rect(0, 0, 4, 1), px.over(0, 0, 0));
        assert(buffer.get(0, 0).char == cui.render.Blocks.HALF, "a picture cell holds an upper half block");
        var top = buffer.get(0, 0).style.fg;
        var bottom = buffer.get(0, 0).style.bg;
        assert(Type.enumEq(top, Color.Rgb(255, 0, 0)), "the character is the pixel above the line");
        assert(Type.enumEq(bottom, Color.Rgb(0, 0, 0)), "and the background the one below it");

        // --- Sixel, read back ---
        var sixel = cui.render.Sixel.encode(px.over(0, 0, 0));
        assert(StringTools.startsWith(sixel, "\x1bP") && StringTools.endsWith(sixel, "\x1b\\"), "a sixel picture is one DCS string");
        var back = readSixel(sixel, 4, 3);
        assert(back != null, "and it parses back");
        // A picture of no more than 256 colours takes its own as the palette,
        // so the only thing lost is the format's own step: a Sixel colour is a
        // percentage of each channel, which is 255 in a hundred parts.
        var off = 0;
        for (y in 0...3) for (x in 0...4)
            for (channel in [
                Std.int(Math.abs(back.red(x, y) - flat.red(x, y))),
                Std.int(Math.abs(back.green(x, y) - flat.green(x, y))),
                Std.int(Math.abs(back.blue(x, y) - flat.blue(x, y)))
            ]) if (channel > off) off = channel;
        assert(off <= 2, "a picture of few colours keeps them all, to the format's own step (worst " + off + ")");

        // More colours than registers: the palette is cut from the picture,
        // and what comes back is close rather than stepped. A gradient through
        // a fixed cube of 216 was what the Farceur switcher saw in steps.
        var gradient = new cui.render.Pixels(64, 6);
        for (y in 0...6) for (x in 0...64)
            gradient.set(x, y, Std.int(x * 4 + y), Std.int(255 - x * 3), Std.int((x * 7 + y * 11) % 256), 255);
        var read = readSixel(cui.render.Sixel.encode(gradient), 64, 6);
        var worst = 0;
        for (y in 0...6) for (x in 0...64) {
            for (channel in [
                Std.int(Math.abs(read.red(x, y) - gradient.red(x, y))),
                Std.int(Math.abs(read.green(x, y) - gradient.green(x, y))),
                Std.int(Math.abs(read.blue(x, y) - gradient.blue(x, y)))
            ]) if (channel > worst) worst = channel;
        }
        assert(worst <= 8, "a picture of many colours comes back within a step of itself (worst " + worst + ")");

        // --- kitty, read back ---
        var kitty = cui.render.Kitty.encode(px, 2, 1);
        assert(kitty.indexOf("a=T,q=2,f=32,s=4,v=3,c=2,r=1") > 0, "a kitty picture says its size in pixels and in cells");
        var payload = kitty.substring(kitty.indexOf(";") + 1, kitty.indexOf("\x1b\\", 2));
        var raw = haxe.crypto.Base64.decode(payload);
        assert(raw.length == 4 * 3 * 4, "and carries every pixel, unquantised");
        assert(raw.get(0) == 255 && raw.get(1) == 0 && raw.get(3) == 255, "the first of them being the red one");

        // --- What the terminal can do ---
        cui.term.Graphics.say(HalfBlocks);
        assert(cui.term.Graphics.sequence(px, 2, 1) == null, "with no protocol there is no sequence: the cells are drawn");
        cui.term.Graphics.say(SixelGraphics, 10, 20);
        var sized = cui.term.Graphics.sequence(px, 2, 1);
        assert(sized != null && StringTools.startsWith(sized, "\x1bP"), "with Sixel there is one");
        assert(sized.indexOf("\"1;1;20;20") > 0, "scaled to the cells it was given");
        // A character a terminal draws as a picture is given the room it
        // paints over, measured in a terminal rather than derived.
        assert(cui.nui.Icons.cellsOf("settings") == 2 && cui.nui.Icons.cellsOf("mic") == 2
            && cui.nui.Icons.cellsOf("menu") == 1,
            "a character drawn as a picture asks for two cells, a plain one for one");
        var gear = new cui.ui.Icon("settings");
        assert(gear.measure(Unbounded).width == 2, "so the layout leaves it two");
        var drawn = new Buffer(12, 1);
        gear.render(drawn, new Rect(0, 0, 12, 1));
        assert(drawn.get(0, 0).char == cui.nui.Icons.glyphOf("settings"), "the character going in the first of them");
        assert(drawn.get(1, 0).continuation, "and the second belonging to it, which the renderer does not write");

        // The other case, which no name in the table needs any more: the
        // terminal advances one cell and paints over the next, so the cell
        // after is a blank that IS written.
        var own = new cui.ui.Icon("settings");
        cui.nui.Icons.ROOM.set("settings", Inked);
        var inked = new Buffer(12, 1);
        own.render(inked, new Rect(0, 0, 12, 1));
        assert(inked.get(1, 0).char == " " && !inked.get(1, 0).continuation,
            "a character whose ink overruns is given a blank cell the renderer writes");
        cui.nui.Icons.ROOM.set("settings", Wide);

        // A character the terminal advances two cells for: the second is not
        // a cell anybody may write.
        var wide = new Buffer(12, 1);
        wide.setWide(3, 0, "X", new Style());
        assert(wide.get(4, 0).continuation, "the cell after a wide character belongs to it");
        wide.set(4, 0, "y", new Style());
        assert(!wide.get(4, 0).continuation, "and writing there frees it again");
        cui.term.Graphics.say(KittyGraphics);
        assert(StringTools.startsWith(cui.term.Graphics.sequence(px, 2, 1), "\x1b_G"), "and with kitty, the other one");

        // --- The buffer carries it, and the renderer writes it where it is ---
        var withPicture = new Buffer(6, 2);
        withPicture.graphic(2, 1, "\x1b_Gsomething\x1b\\");
        assert(withPicture.graphics.length == 1, "a picture is recorded beside the cells");
        withPicture.clear();
        assert(withPicture.graphics.length == 0, "and cleared with them");
    }

    /**
        A sixel string back into pixels, so the encoder is read rather than
        believed. Six rows a band, `$` returns to the start of one and `-`
        moves to the next; `!n` repeats the character that follows.
    **/
    static function readSixel(sixel:String, width:Int, height:Int):cui.render.Pixels {
        var out = new cui.render.Pixels(width, height);
        var palette = new Map<Int, {r:Int, g:Int, b:Int}>();
        var at = sixel.indexOf("q") + 1;
        var band = 0;
        var x = 0;
        var colour = 0;
        while (at < sixel.length) {
            var c = sixel.charAt(at);
            if (c == "\x1b") break;
            if (c == "\"") { // the size, which this reader takes from its caller
                at++;
                while (at < sixel.length && "0123456789;".indexOf(sixel.charAt(at)) >= 0) at++;
                continue;
            }
            if (c == "#") {
                at++;
                var digits = "";
                while (at < sixel.length && sixel.charAt(at) >= "0" && sixel.charAt(at) <= "9") digits += sixel.charAt(at++);
                colour = Std.parseInt(digits);
                x = 0;
                if (at < sixel.length && sixel.charAt(at) == ";") {
                    // A definition: ;2;r;g;b in percent.
                    var numbers = [];
                    while (at < sixel.length && (sixel.charAt(at) == ";" || (sixel.charAt(at) >= "0" && sixel.charAt(at) <= "9"))) {
                        if (sixel.charAt(at) == ";") { numbers.push(""); at++; continue; }
                        numbers[numbers.length - 1] += sixel.charAt(at++);
                    }
                    var value = function(i:Int) return Math.round(Std.parseInt(numbers[i]) * 255 / 100);
                    palette.set(colour, {r: value(1), g: value(2), b: value(3)});
                }
                continue;
            }
            if (c == "$") { x = 0; at++; continue; }
            if (c == "-") { band++; x = 0; at++; continue; }
            var run = 1;
            if (c == "!") {
                at++;
                var digits = "";
                while (at < sixel.length && sixel.charAt(at) >= "0" && sixel.charAt(at) <= "9") digits += sixel.charAt(at++);
                run = Std.parseInt(digits);
                c = sixel.charAt(at);
            }
            at++;
            var bits = c.charCodeAt(0) - 63;
            if (bits < 0) continue;
            for (_ in 0...run) {
                for (row in 0...6) {
                    if (bits & (1 << row) == 0) continue;
                    var y = band * 6 + row;
                    if (x < width && y < height) {
                        var rgb = palette.get(colour);
                        if (rgb != null) out.set(x, y, rgb.r, rgb.g, rgb.b, 255);
                    }
                }
                x++;
            }
        }
        return out;
    }

    /**
        A choice among options, on the one row a terminal can give it.

        The drawing is what is checked, not the intent: a picker that cycles is
        only honest if the row says which option of how many is showing, and if
        the arrow at the end of the list is dim. Read back out of the buffer,
        because a control is proved by the cells it wrote.
    **/
    static function testPicker():Void {
        section("Picker");

        var at = new cui.state.State.IntState(0, "at");
        var picker = new cui.ui.Picker("Transition", ["Cut", "Mix", "Wipe"],
            cui.ui.Picker.PickerBinding.fromState(at));

        var buf = new Buffer(30, 1);
        picker.render(buf, new Rect(0, 0, 30, 1));
        assert(row(buf, 1).indexOf("Transition") == 0, "the label is drawn");
        assert(row(buf, 1).indexOf("Cut") > 0, "and the option chosen");
        assert(row(buf, 1).indexOf("1/3") > 0,
            "and which of how many, since only one shows (\"" + row(buf, 1) + "\")");

        // Right moves on, Left comes back, and neither leaves the list.
        picker.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Right)));
        assert(at.get() == 1, "Right moves to the next option");
        picker.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Left)));
        picker.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Left)));
        assert(at.get() == 0, "Left stops at the first, rather than going below it");

        // Enter wraps: a list of two must be reachable with one key.
        at.set(2);
        picker.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Enter)));
        assert(at.get() == 0, "Enter past the end comes back to the first");

        // The row does not change width as it cycles, or a panel would shift
        // under the eye every time somebody chose something.
        at.set(0);
        var narrow = new Buffer(30, 1);
        picker.render(narrow, new Rect(0, 0, 30, 1));
        at.set(2);
        var wide = new Buffer(30, 1);
        picker.render(wide, new Rect(0, 0, 30, 1));
        assert(StringTools.rtrim(row(narrow, 1)).length == StringTools.rtrim(row(wide, 1)).length,
            "the row keeps its width whatever is chosen");

        // --- A key belongs to the view that has focus ---
        //
        // Benjamin, on a row of five: "left/right ne respecte pas le focus sur
        // les pickers". Two defects met. The tree pass -- which exists so a
        // ScrollView can scroll and a Tabs can change tab, neither being
        // focusable -- offered the event to EVERY view, so a key the focused
        // view declined went looking for a taker and the first picker in the
        // tree took it. And this picker declined Right at the end of its list
        // instead of consuming it, which is what set the key loose.
        var first = new cui.state.State.IntState(0, "first");
        var second = new cui.state.State.IntState(1, "second");
        var panel = new VStack([
            new cui.ui.Picker("A", ["a1", "a2", "a3"], cui.ui.Picker.PickerBinding.fromState(first)),
            new cui.ui.Picker("B", ["b1", "b2"], cui.ui.Picker.PickerBinding.fromState(second)),
        ], 0);

        // The second picker is at the end of its list: Right does nothing, and
        // says it took the key anyway.
        var atEnd:cui.ui.Picker = cast panel.children[1];
        assert(atEnd.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Right))),
            "a picker at the end of its list still takes Right");
        assert(second.get() == 1 && first.get() == 0,
            "and nothing moved, neither it nor its neighbour");

        // Every view here that handles a key is focusable, which is why the
        // loop no longer has a pass over the tree for the others: there are no
        // others, and that pass could only ever reach a view behind focus's
        // back. Checked rather than asserted in prose, since the day one of
        // these stops being focusable is the day the rule needs revisiting.
        for (built in [
            (new cui.ui.Button("b", () -> {}) : View),
            new cui.ui.Checkbox("c", new cui.ui.Checkbox.CheckboxBinding(() -> false, _ -> {})),
            new cui.ui.Picker("p", ["x"], new cui.ui.Picker.PickerBinding(() -> 0, _ -> {})),
            new cui.ui.ScrollView([new VStack([new Text("a")], 0)],
                new cui.ui.ScrollView.ScrollOffset(() -> 0, _ -> {})),
        ]) {
            assert(built.focusable, "a view that handles keys is focusable");
        }

        // An empty list is legal, and must not be a crash.
        var none = new cui.ui.Picker("Nothing", [], new cui.ui.Picker.PickerBinding(() -> 0, _ -> {}));
        none.render(new Buffer(20, 1), new Rect(0, 0, 20, 1));
        assert(none.index() == -1, "an empty picker chooses nothing");

        // --- one that arrived as data ---
        var reported = -1;
        var node = new nui.Node("Picker")
            .prop("label", nui.PropValue.PString("Source"))
            .prop("selectedIndex", nui.PropValue.PInt(1))
            .prop("onSelect", nui.PropValue.PCallbackInt(i -> reported = i));
        for (option in ["CAM 1", "CAM 2"])
            node.child(new nui.Node("Text").prop("text", nui.PropValue.PString(option)));

        var received = NodeRenderer.build(node);
        var rbuf = new Buffer(30, 1);
        received.render(rbuf, new Rect(0, 0, 30, 1));
        assert(row(rbuf, 1).indexOf("CAM 2") > 0, "a received picker shows the option it was sent");

        received.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Left)));
        assert(reported == 0, "and reports a choice rather than applying it");
        var after = new Buffer(30, 1);
        received.render(after, new Rect(0, 0, 30, 1));
        assert(row(after, 1).indexOf("CAM 2") > 0,
            "what it shows next is still the sender's, which is the rule for a received tree");

        // Over a wire every action is a string callback: an index cast into
        // that slot is the defect pui paid for, so it is stringified.
        var text = "";
        var inflated = new nui.Node("Picker")
            .prop("selectedIndex", nui.PropValue.PInt(0))
            .prop("onSelect", nui.PropValue.PCallbackString(s -> text = s));
        inflated.child(new nui.Node("Text").prop("text", nui.PropValue.PString("a")));
        inflated.child(new nui.Node("Text").prop("text", nui.PropValue.PString("b")));
        NodeRenderer.build(inflated)
            .handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Right)));
        assert(text == "1", "an index reaches a string callback as its text (\"" + text + "\")");
    }

    /** One rendered line, as text. **/
    static function row(buf:Buffer, y:Int):String {
        var out = "";
        for (x in 0...buf.width) out += buf.get(x, y - 1).char;
        return out;
    }

    /**
        Typing into a field, and moving the caret while doing it.

        cui rebuilds the whole tree on every state write, so the field object is
        thrown away mid-word. The caret used to live in that object and the
        constructor put it at the end of the text, so moving it was impossible:
        Left decremented it, asked for a redraw, and the redraw built a field
        whose caret was at the end again. Typing worked only because the end is
        where it already wanted to be.

        Measured in a terminal before it was fixed: `abc`, Left, Left, `X` gave
        `abcX`.
    **/
    static function testEditing():Void {
        section("Editing a field");

        var value = new cui.state.State<String>("", "value");
        var field = new cui.ui.Input(cui.state.Binding.from(value), "Name");
        var page = new VStack([field], 0);

        // A field is reached through focus, so the ring has to exist and hold
        // it -- the caret is kept per slot of that ring, never per object.
        View.focusManager = new cui.focus.FocusManager();
        View.focusManager.buildFocusRing(page);

        for (c in ["a", "b", "c"]) {
            field.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Char(c))));
            // What the loop does after every write: a new tree, a new field.
            page = new VStack([field = new cui.ui.Input(cui.state.Binding.from(value), "Name")], 0);
            View.focusManager.buildFocusRing(page);
        }
        assert(value.get() == "abc", "three letters land in order (\"" + value.get() + "\")");

        field.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Left)));
        field.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Left)));
        // A caret move rebuilds too -- it asks for the redraw itself.
        page = new VStack([field = new cui.ui.Input(cui.state.Binding.from(value), "Name")], 0);
        View.focusManager.buildFocusRing(page);

        field.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Char("X"))));
        assert(value.get() == "aXbc",
            "and the caret stays where it was put, across the rebuild (\"" + value.get() + "\")");

        field.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Home)));
        field.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Char("0"))));
        assert(value.get() == "0aXbc", "Home reaches the front (\"" + value.get() + "\")");

        View.focusManager = null;
    }

    /**
        The editable controls of a tree that arrived.

        cui described a Toggle, a Slider and a TextInput outward and drew none
        of them inward: a received panel showed `?Toggle` where a switch should
        be. cui hosts Companion, so that was a real panel.
    **/
    static function testReceivedControls():Void {
        section("Received controls");

        var flipped:Array<Bool> = [];
        var toggle = NodeRenderer.build(new nui.Node("Toggle")
            .prop("label", nui.PropValue.PString("Tally"))
            .prop("isOn", nui.PropValue.PBool(true))
            .prop("onToggle", nui.PropValue.PCallbackBool(v -> flipped.push(v))));
        assert(Std.isOfType(toggle, cui.ui.Checkbox), "a received Toggle is a checkbox");
        var shown = new Buffer(30, 1);
        toggle.render(shown, new Rect(0, 0, 30, 1));
        assert(row(shown, 1).indexOf("Tally") > 0, "with the label it was sent");
        assert(row(shown, 1).indexOf("✓") >= 0, "and ticked, as it was sent");
        toggle.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Enter)));
        assert(flipped.length == 1 && flipped[0] == false, "flipping it reports the new value");

        var levels:Array<Float> = [];
        var slider = NodeRenderer.build(new nui.Node("Slider")
            .prop("value", nui.PropValue.PFloat(0.5))
            .prop("min", nui.PropValue.PFloat(0))
            .prop("max", nui.PropValue.PFloat(1))
            .prop("onValue", nui.PropValue.PCallbackFloat(v -> levels.push(v))));
        assert(Std.isOfType(slider, cui.ui.Slider), "a received Slider is a slider");
        var bar = new Buffer(30, 1);
        slider.render(bar, new Rect(0, 0, 30, 1));
        assert(row(bar, 1).indexOf("50%") > 0, "showing the level it was sent");
        slider.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Right)));
        assert(levels.length == 1 && levels[0] > 0.5, "and a drag reports a bigger one");

        // A field of a received tree: what it shows while being typed in is
        // what was typed, not what the sender last said. The sender here never
        // answers at all, which is the worst case of being behind.
        var typed:Array<String> = [];
        var node = new nui.Node("TextInput")
            .prop("text", nui.PropValue.PString("Fondu"))
            .prop("onText", nui.PropValue.PCallbackString(s -> typed.push(s)));
        var received = NodeRenderer.build(node);
        var panel = new VStack([received], 0);
        View.focusManager = new cui.focus.FocusManager();
        View.focusManager.buildFocusRing(panel);

        received.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Char("A"))));
        // The rebuild the keystroke caused, with the sender still behind.
        received = NodeRenderer.build(node);
        panel = new VStack([received], 0);
        View.focusManager.buildFocusRing(panel);
        received.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Char("B"))));

        assert(typed[typed.length - 1] == "FonduAB",
            "a received field keeps what was typed while its sender is behind (\""
            + typed[typed.length - 1] + "\")");

        View.focusManager = null;
    }

    /**
        The focus belongs to the cell, not to the slot.

        The ring is rebuilt every frame and the focus was an index into it, so
        a focusable control appearing ABOVE the field being typed into moved
        the focus -- and the caret and the draft, keyed by the same slot -- to
        another control.
    **/
    static function testFocusFollowsTheCell():Void {
        section("Focus follows the cell");

        var first = new cui.state.State.StringState("", "focusFirst");
        var second = new cui.state.State.StringState("", "focusSecond");
        var extra = new cui.state.State.BoolState(false, "focusExtra");

        function page(withExtra:Bool):View {
            var rows:Array<View> = [];
            if (withExtra) rows.push(new cui.ui.Checkbox("extra", extra));
            rows.push(new cui.ui.Input(first, "first"));
            rows.push(new cui.ui.Input(second, "second"));
            return new VStack(rows, 0);
        }

        View.focusManager = new cui.focus.FocusManager();
        var before = page(false);
        View.focusManager.buildFocusRing(before);
        View.focusManager.focusView(before.children[1]);
        View.focusManager.dispatchToFocused(Key(new cui.event.KeyEvent.KeyEvent(Char("a"))));
        assert(second.get() == "a", "typing lands in the focused field");

        var after = page(true);
        View.focusManager.buildFocusRing(after);
        assert(View.focusManager.currentFocus() == after.children[2],
            "a control inserted above: the focus followed the field, not the slot");
        View.focusManager.dispatchToFocused(Key(new cui.event.KeyEvent.KeyEvent(Char("b"))));
        assert(second.get() == "ab", "the next keystroke lands in the same cell, after the caret (\"" + second.get() + "\")");
        assert(first.get() == "" && extra.get() == false, "and nowhere else");

        // A control that edits nothing is still followed by position.
        var buttons = new VStack([new cui.ui.Button("one", () -> {}), new cui.ui.Button("two", () -> {})], 0);
        View.focusManager = new cui.focus.FocusManager();
        View.focusManager.buildFocusRing(buttons);
        View.focusManager.focusNext();
        View.focusManager.buildFocusRing(buttons);
        assert(View.focusManager.focusIndex == 1, "a control that edits nothing keeps its position");

        View.focusManager = null;
    }

    /**
        A password field: masked, and the value is the application's.

        The difference from a secret is purpose. Here the application binds the
        value, pre-fills it and reads it back; the field simply never shows it.
    **/
    /**
        What the controls declare, and what both directions do with it.

        Both were hand-written and facing each other -- twenty-four cases
        against twenty-two -- and they had already drifted in two ways this
        section now pins.
    **/
    static function testVocabulary():Void {
        section("Vocabulary");

        // --- colour ---
        //
        // cui described a colour as `Std.string` of its enum value -- literally
        // "Named(Red)" on the wire -- and the receiving side parsed only bare
        // names like "red". So a colour did not survive a round trip at ALL: it
        // came back as nothing. Nobody had looked at a coloured tree crossing.
        for (colour in [cui.render.Color.Named(Red), cui.render.Color.Rgb(200, 50, 60),
                cui.render.Color.Role("danger")]) {
            var painted = new cui.ui.Text("x");
            painted.backgroundColor(colour);
            var sent = cui.nui.Describe.describe(painted);
            var again = cui.nui.Describe.describe(NodeRenderer.build(sent));
            assert(again.modifiers.length == 1
                && again.modifiers[0].strings[0] == sent.modifiers[0].strings[0],
                "a colour survives the round trip: " + Std.string(colour)
                + " -> " + Std.string(sent.modifiers[0].strings));
        }

        // A ROLE STAYS A ROLE. Resolved on the way through, a tree relayed by a
        // terminal would reach the far end carrying a number, with nothing left
        // to say it had ever been a role.
        var relayed = new cui.ui.Text("STREAM");
        relayed.backgroundColor(cui.render.Color.Role("danger"));
        assert(cui.nui.Describe.describe(relayed).modifiers[0].strings[0] == "role:danger",
            "and a role is still a role after it");

        // A role becomes one of the sixteen, so it follows the palette the
        // person set -- better than exact, not worse.
        assert(cui.nui.Colors.named("danger") == BrightRed
            && cui.nui.Colors.named("success") == BrightGreen,
            "a role is drawn in one of the terminal's own sixteen");
        assert(cui.nui.Colors.resolve("#c8323c80") != null
            && Std.string(cui.nui.Colors.resolve("#c8323c80")) == "Rgb(200,50,60)",
            "components are exact, and opacity is dropped: a cell is opaque");
        assert(cui.nui.Colors.resolve("red") == null,
            "and a named colour does not cross");

        // Nineteen since 2026-09-21: `ScrollView`, `Spacer` and `ZStack` were
        // written but undeclared, which is why `mui/examples/kitchen-sink`
        // could not be built for this backend. The number is asserted on
        // purpose -- a control that stops being read should fail here rather
        // than go missing from a screen.
        assert(CuiProbe.verify() == 19, "every declared control is read, and none refused");

        // THE ONE THAT MATTERED. `cui.ui.Password` extends `cui.ui.Input`, and
        // `Describe` chose its branch with `Std.isOfType` in written order --
        // so a password fell into the `TextInput` branch and crossed as an
        // ORDINARY field. The far side has no way to know, and draws it in
        // clear. A flag fails open; a type fails closed, and the type is now
        // what the declaration says rather than what the branch order does.
        var secret = new cui.state.State<String>("hunter2", "pw");
        var field = new cui.ui.Password(cui.state.Binding.from(secret), "Mot de passe");
        var sent = cui.nui.Describe.describe(field);
        assert(sent.type == "PasswordInput", "a password crosses as a password, not as a field");
        var back = NodeRenderer.build(sent);
        assert(Std.isOfType(back, cui.ui.Password), "and is rebuilt as one");
        assert(cui.nui.Describe.describe(new cui.ui.Input(cui.state.Binding.from(secret), "")).type == "TextInput",
            "while an ordinary field is still an ordinary field");

        // Four types `Describe` emitted had no case in `NodeRenderer` at all:
        // a tree cui described, cui could not draw back.
        var undrawn = [];
        for (entry in CuiProbe.all().split(";")) {
            var type = entry.split("|")[0];
            var drawn = NodeRenderer.build(new nui.Node(type));
            if (Std.isOfType(drawn, cui.ui.Text)
                && StringTools.startsWith((cast drawn : cui.ui.Text).content, "?"))
                undrawn.push(type);
        }
        assert(undrawn.join(",") == "", "every declared type is one the renderer draws: " + undrawn.join(","));

        // Out and back, for every declared type. Compared to ITSELF rather
        // than to what was sent, because some values are normalised on the way
        // in and should be -- what must hold is that a tree already through
        // the round trip does not keep changing.
        var lost = [];
        for (entry in CuiProbe.all().split(";")) {
            var type = entry.split("|")[0];
            var node = new nui.Node(type);
            for (declared in entry.split("|")[1].split(",")) {
                if (declared == "") continue;
                var parts = declared.split(":");
                node.prop(parts[0], switch (parts[1]) {
                    case "Bool": PBool(true);
                    case "Int": PInt(3);
                    case "Float": PFloat(0.5);
                    case _: PString("x-" + parts[0]);
                });
            }
            var once = cui.nui.Describe.describe(NodeRenderer.build(node));
            if (once.type != type) { lost.push(type + " -> " + once.type); continue; }
            var twice = cui.nui.Describe.describe(NodeRenderer.build(once));
            for (name in once.props.keys()) {
                var before = Std.string(once.props.get(name));
                if (StringTools.startsWith(before, "PCallback")) continue;
                if (before != Std.string(twice.props.get(name)))
                    lost.push(type + "." + name + ": " + before + " -> " + Std.string(twice.props.get(name)));
            }
        }
        assert(lost.join(" | ") == "", "every declared property survives node -> view -> node: " + lost.join(" | "));
    }

    static function testPassword():Void {
        section("Password");

        var value = new cui.state.State<String>("hunter2", "pw");
        var field = new cui.ui.Password(cui.state.Binding.from(value), "Password");
        var page = new VStack([field], 0);
        View.focusManager = new cui.focus.FocusManager();
        View.focusManager.buildFocusRing(page);

        var buf = new Buffer(30, 1);
        field.render(buf, new Rect(0, 0, 30, 1));
        var drawn = row(buf, 1);
        assert(drawn.indexOf("hunter2") < 0, "the value is never drawn");
        assert(drawn.indexOf("\u2022\u2022\u2022\u2022\u2022\u2022\u2022") == 0,
            "seven characters are seven marks (\"" + drawn + "\")");

        // The application has it, which is the whole point.
        assert(value.get() == "hunter2", "and the bound value is untouched");
        field.handleEvent(Key(new cui.event.KeyEvent.KeyEvent(Char("!"))));
        assert(value.get() == "hunter2!", "typing reaches the binding, as in any field");

        // An ordinary field is not masked by this.
        var plain = new cui.ui.Input(cui.state.Binding.from(value), "Name");
        var plainBuf = new Buffer(30, 1);
        plain.render(plainBuf, new Rect(0, 0, 30, 1));
        assert(row(plainBuf, 1).indexOf("hunter2!") == 0,
            "an ordinary Input still shows its text");

        View.focusManager = null;
    }

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
        testTextStyle();
        testIconsAndPictures();
        testPictures();
        testNuiSource();
        testNuiRenderer();
        testPicker();
        testEditing();
        testReceivedControls();
        testPassword();
        testFocusFollowsTheCell();
        testVocabulary();
        testClip();
        testControlsCut();

        Sys.println('\n$passed passed, $failed failed');
        if (failed > 0) Sys.exit(1);
    }
}

/**
	A view that writes past whatever rectangle it is handed.

	Nothing in `cui` does this on purpose -- a `Text` wraps to its width -- but
	nothing stops one either: `Buffer.set` clips to the terminal, not to a
	view. That is the gap `Clip` closes, and proving it needs a child that
	actually overdraws rather than one that happens to behave.
**/
class Overdrawer extends cui.View {
	public function new() super();

	override public function measure(c:cui.layout.Constraint):cui.layout.Size
		return new cui.layout.Size(12, 1);

	override public function render(buffer:cui.render.Buffer, area:cui.layout.Rect):Void {
		var word = "ABCDEFGHIJKL";
		for (i in 0...word.length)
			buffer.set(area.x + i, area.y, word.charAt(i), new cui.render.Style());
	}
}
