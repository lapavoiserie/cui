import mui.macros.Markup.ui;

/**
	`ui(<VStack>…)` compiled against `cui`'s own declarations.

	`mui` refuses to compile markup against a backend that registers nothing, so
	a file that compiles at all has been checked against `cui.nui.Vocabulary` —
	and what it produces is drawn by `cui.nui.NodeRenderer`, which is the path a
	received tree takes.
**/
class MarkupCheck {
	static var failures = 0;

	static function check(what:String, ok:Bool, ?extra:Dynamic):Void {
		Sys.println((ok ? "ok   " : "FAIL ") + what + (ok || extra == null ? "" : " — " + extra));
		if (!ok) failures++;
	}

	static function main() {
		var muted = false;
		var picked = -1;
		var sources = ["Caméra", "Pupitre"];

		var tree = ui(<VStack spacing={1}>
			<Text text="Régie"/>
			<Toggle label="Muet" isOn={muted} onToggle={v -> muted = v}/>
			<Picker label="Source" selectedIndex={0} onSelect={i -> picked = i}>
				{[for (s in sources) ui(<Text text={s}/>)]}
			</Picker>
			<Button label="Fondu" onClick={() -> {}}/>
		</VStack>);

		check("the markup builds the declared type", tree.type == "VStack");
		check("children keep the order they were written in",
			[for (c in tree.children) c.type].join(",") == "Text,Toggle,Picker,Button",
			[for (c in tree.children) c.type].join(","));
		check("a Picker's options arrived as Text children",
			tree.children[2].children.length == 2);
		check("a two-way act carries what its value is",
			switch (tree.children[1].props.get("onToggle")) {
				case PCallbackBool(_): true; case _: false;
			});

		switch (tree.children[1].props.get("onToggle")) { case PCallbackBool(f): f(true); case _: }
		check("and a write through it reaches the application", muted == true);

		var view = cui.nui.NodeRenderer.build(tree);
		check("and cui draws a view out of it", Std.isOfType(view, cui.ui.VStack));

		Sys.println(failures == 0 ? "\nall checks passed" : '\n$failures failed');
		Sys.exit(failures == 0 ? 0 : 1);
	}
}
