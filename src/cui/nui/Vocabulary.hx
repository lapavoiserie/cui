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
	public static final DIALECT:Dialect = {pack: "cui.ui", view: "cui.View"};

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
