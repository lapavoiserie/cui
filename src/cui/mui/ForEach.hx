package cui.mui;

/**
	`cui`'s conformance for `mui.ui.ForEach`.

	A macro rather than a class, because what a loop compiles to is the one place
	the six backends have nothing in common. `mui` used to hold all six shapes in
	`mui.macros.ForEachMacro`; each now lives with the backend that means it.
**/
class ForEach {
	/** Build a list of views, one per item. **/
	public static macro function build(items:haxe.macro.Expr,
			builder:haxe.macro.Expr):haxe.macro.Expr {
		// cui's ForEach takes the array, not the cell, so the read happens here.
		return macro new cui.ui.ForEach($items.get(), $builder);
	}
}
