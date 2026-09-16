package cui.render;

import haxe.io.Bytes;

/**
	The pixels behind a canonical `src`, by scheme.

	`data:` carries them, `file:` and `asset:` name a file -- an asset being one
	the application ships, beside the executable or where it was started, the
	directory `mui.Assets.src` checks a name against. `https:` is not fetched
	here: a terminal application that reached for the web on its own would do
	it while the panel is being drawn, and a picture that must cross a network
	arrives through `dui` instead, already pulled and checked.

	Only PNG. A JPEG is a different decoder, and one that is not written yet is
	better said than half-drawn: what cannot be decoded shows the `alt`.
**/
class Picture {
	static final known:Map<String, Null<Pixels>> = new Map();

	/** The pixels for a source, decoded once, or `null` for what cannot be. **/
	public static function of(src:String):Null<Pixels> {
		if (src == null || src == "") return null;
		if (known.exists(src)) return known.get(src);
		var pixels = decode(src);
		known.set(src, pixels);
		return pixels;
	}

	static function decode(src:String):Null<Pixels> {
		var bytes = bytesOf(src);
		return bytes == null ? null : Png.decode(bytes);
	}

	static function bytesOf(src:String):Null<Bytes> {
		return switch (nui.ImageSource.parse(src)) {
			case Data(_, base64): try haxe.crypto.Base64.decode(base64) catch (_:Dynamic) null;
			case File(path): read(path);
			case Asset(path, _): read(assetPath(path));
			case _: null;
		}
	}

	static function read(path:Null<String>):Null<Bytes> {
		#if sys
		if (path == null || !sys.FileSystem.exists(path) || sys.FileSystem.isDirectory(path)) return null;
		return try sys.io.File.getBytes(path) catch (_:Dynamic) null;
		#else
		return null;
		#end
	}

	/** Beside the executable, or beside where the application was started. **/
	static function assetPath(path:String):Null<String> {
		#if sys
		if (path.indexOf("..") >= 0) return null;
		var exe = haxe.io.Path.directory(Sys.programPath());
		for (candidate in [haxe.io.Path.join([exe, "assets", path]), haxe.io.Path.join(["assets", path])])
			if (sys.FileSystem.exists(candidate)) return candidate;
		return null;
		#else
		return null;
		#end
	}
}
