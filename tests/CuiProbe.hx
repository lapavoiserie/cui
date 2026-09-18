/**
	What `cui.nui.Vocabulary` reads, computed while compiling.

	Its own class: a macro cannot be called from the module it is testing when
	that module is also being built.
**/
class CuiProbe {
	/** How many declared controls were read whole, every refusal included. **/
	public static macro function verify():haxe.macro.Expr
		return macro $v{cui.nui.Vocabulary.verify()};

	/** Every type and its props: `type|name:kind:callback,…`, `;` between. **/
	public static macro function all():haxe.macro.Expr {
		var out = [];
		var types = [for (t in cui.nui.Vocabulary.types().keys()) t];
		types.sort(Reflect.compare);
		for (type in types) {
			var props = [];
			for (p in cui.nui.Vocabulary.propsFor(type))
				props.push(p.name + ":" + p.kind + ":" + (p.callback == null ? "-" : p.callback));
			out.push(type + "|" + props.join(","));
		}
		return macro $v{out.join(";")};
	}
}
