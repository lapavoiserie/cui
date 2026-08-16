package cui.kui;

/**
	Which operating system a `cui` build is for, told to `kui`.

	Called once from the build file:

	```
	--macro cui.kui.Platform.registerWithKui()
	```

	A terminal application is the one case where the backend genuinely does not
	pick a platform — it runs wherever it is compiled. So this answers from the
	machine doing the compiling, which is right for the ordinary build and
	**wrong the moment someone cross-compiles**. `-D kui_platform` overrides it,
	and that is the answer for a cross build rather than a cleverer guess here.

	`cui` links through hxcpp and generates no native project of its own, so a
	capability's payload rides on `@:buildXml` and nothing else has to learn
	anything. It is the cheapest backend to serve, and the reason it is a good
	second one to prove: the same capability, a different backend, no new work.
**/
class Platform {
	/** Hand `kui` the platform and the link steps this build has. **/
	public static function registerWithKui():Void {
		#if macro
		var platform = switch (Sys.systemName()) {
			case "Mac": "macos";
			case "Windows": "windows";
			case "Linux": "linux";
			case _: null;
		}
		if (platform != null)
			kui.macros.Host.register({
				platform: platform,
				toolchains: ["hxcpp"],
				backend: "cui",
			});
		#end
	}
}
