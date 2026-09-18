package cui.nui;

#if macro
import haxe.macro.Expr.Field;
#end

/**
	Both directions, written by `cui`'s declarations rather than by hand.

	The generator is `nui.macros.Derive`, shared by every backend; this names
	the five things that are `cui`'s own. See there for why both directions come
	from one place, how describing dispatches by nearest declared ancestor
	rather than by the order somebody wrote `if`s, and what stays hand-written.
**/
class Derive {
	#if macro
	/** Build `cui.nui.Derived`'s two maps from what the controls declare. **/
	public static function build():Array<Field>
		return nui.macros.Derive.build({
			pack: "cui.ui",
			view: "cui.View",
			cells: "cui.nui.Cells",
			readers: "cui.nui.NodeRenderer",
			appendChildren: "cui.nui.Describe.appendChildren",
		});
	#end
}
