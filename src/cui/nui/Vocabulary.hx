package cui.nui;

#if macro
import haxe.macro.Context;
import nui.macros.Declarations;
import nui.macros.Declarations.Action;
import nui.macros.Declarations.Children;
import nui.macros.Declarations.Dialect;
import nui.macros.Declarations.Prop;
#end

/**
	What `cui` can build and describe, read from the controls themselves.

	The reading lives in `nui.macros.Declarations`, shared by every backend.
	This file is what is `cui`'s own: which controls, what a view is, and the
	schema handed to `mui` so `ui(<VStack>…)` can be checked against them.
**/
class Vocabulary {
	/** Kept so the class exists outside macro context. **/
	public static var DUMMY(default, never):Int = 0;

	#if macro
	/**
		What the declaration readers are told about this backend.

		`cells` and `readers` used to live only in `cui.nui.Derive`, because
		only the generated builders needed them. `nui.macros.Construct` needs
		the same two -- it builds the same controls, one stage earlier, from
		markup -- and a second copy of the answer is a second place to get it
		wrong. One dialect, both readers.
	**/
	/**
		The canon's decorations this backend draws on its own views.

		It answered all nine, and drew five: `opacity`, `width`, `height` and
		`flex` fell through to "no terminal equivalent -- skipped on purpose"
		in `NodeRenderer.applyModifiers`. So markup accepted them and the
		screen ignored them, which is exactly what `honoured` exists to stop.
		Width, height and opacity are drawn now (see there); `flex` is not --
		`SizePolicy.Fill` is declared and no stack reads it, the stacks share
		space by sniffing for `Spacer` -- so it is refused, by name.
	**/
	public static final HONOURED = ["padding", "backgroundColor", "foregroundColor", "border",
		"opacity", "clip", "width", "height"];

	public static final DIALECT:Dialect = {
		pack: "cui.ui",
		view: "cui.View",
		readers: "cui.nui.NodeRenderer",
		cells: "cui.nui.Cells",
		appendChildren: "cui.nui.Describe.appendChildren",
	};

	public static function types():Map<String, String>
		return Declarations.types(DIALECT);

	public static function propsFor(type:String):Array<Prop>
		return Declarations.propsFor(DIALECT, type);

	public static function actionsFor(type:String):Array<Action>
		return Declarations.actionsFor(DIALECT, type);

	public static function verify():Int
		return Declarations.verify(DIALECT);

	/** Hand `mui` the schema `ui(<VStack>…)` checks a tag against. **/
	#if (mui || mui_backend)
	public static function registerWithMui():Void {
		mui.macros.Backend.register({
			knows: type -> types().exists(type),
			keysOf: keysOf,
			requiredOf: requiredOf,
			kindOf: attributeKind,
			types: () -> [for (type in types().keys()) type],
			// Markup becomes `new cui.ui.VStack(...)` rather than a node the
			// renderer reads back. Behind `-D mui_views` while the two shapes
			// coexist: with it on, `ui()` answers a `cui.View` instead of a
			// `nui.Node`, which is the point and is also a change of type at
			// every call site. See `mui.macros.Backend.Vocabulary.viewOf`.
			#if mui_views
			viewOf: (tag, given, children, pos) ->
				nui.macros.Construct.expr(DIALECT, tag, given, children, pos),
			// The canon's nine, mapped where they were already mapped: a
			// second table here would be a second place for `border` to mean
			// something slightly different.
			decorate: (view, modifiers, pos) -> macro {
				var __view = $view;
				cui.nui.NodeRenderer.applyModifiers(__view,
					[for (__m in ($modifiers : Array<Null<nui.Modifier>>)) if (__m != null) __m]);
				__view;
			},
			// What this backend can actually draw on a view. Markup refuses
			// anything else BY NAME while compiling: a decoration it cannot
			// honour is knowable here, and this project's rule is that
			// something knowable is a compile error rather than a marker or a
			// line in a log. See `mui.macros.Backend.Vocabulary.honoured`.
			honoured: () -> HONOURED,
			#end
		});
	}
	#else
	public static function registerWithMui():Void {
		Context.error("cui.nui.Vocabulary.registerWithMui() was called, but `mui` is "
			+ "not visible from this build.\n"
			+ "  Add `-lib mui`, or `-D mui_backend=cui` if mui is on the class path "
			+ "some other way.", Context.currentPos());
	}
	#end

	/** Every attribute a tag accepts: its properties and its acts. **/
	public static function keysOf(type:String):Array<String> {
		var out = [for (p in propsFor(type)) p.name];
		for (p in propsFor(type)) if (p.callback != null) out.push(p.callback);
		for (a in actionsFor(type)) out.push(a.name);
		return out;
	}

	/** The attributes a tag cannot be written without. **/
	public static function requiredOf(type:String):Array<String>
		return [for (p in propsFor(type)) if (p.argument != null && !p.optional) p.name];

	/** Which `nui.PropValue` constructor an attribute takes. `null` if unknown. **/
	public static function attributeKind(type:String, key:String):Null<String> {
		for (p in propsFor(type)) {
			if (p.name == key) return "K" + p.kind;
			if (p.callback == key) return "KCallback" + p.kind;
		}
		for (a in actionsFor(type))
			if (a.name == key) return a.carries == null ? "KCallback" : "KCallback" + a.carries;
		return null;
	}
	#end
}
