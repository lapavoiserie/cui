package cui.render;

/**
	Pixels through the kitty graphics protocol: kitty, Ghostty, WezTerm.

	The picture crosses as its own bytes -- `f=32` is RGBA, eight bits a channel
	-- so nothing is quantised and nothing is guessed. It is sent in chunks
	because a terminal reads its input in pieces and a single escape of a
	megabyte is how an emulator's parser is made to drop the lot.

	`c` and `r` say how many cells to draw it in: the terminal scales, which is
	better than scaling here, and it means the picture occupies exactly the
	cells the layout gave it.
**/
class Kitty {
	/** As much base64 as one escape carries. **/
	public static inline var CHUNK = 4096;

	/** The whole sequence, ready to write where the cursor stands. **/
	public static function encode(pixels:Pixels, columns:Int, rows:Int):String {
		if (pixels.width <= 0 || pixels.height <= 0) return "";
		var payload = haxe.crypto.Base64.encode(pixels.rgba);
		var out = new StringBuf();
		var at = 0;
		var first = true;
		while (at < payload.length) {
			var piece = payload.substr(at, CHUNK);
			at += CHUNK;
			var more = at < payload.length ? 1 : 0;
			out.add("\x1b_G");
			if (first) {
				// a=T: transmit and display at once. q=2: say nothing back --
				// a reply would arrive in the middle of key input.
				out.add('a=T,q=2,f=32,s=${pixels.width},v=${pixels.height},c=$columns,r=$rows,m=$more');
				first = false;
			} else {
				out.add('m=$more');
			}
			out.add(";");
			out.add(piece);
			out.add("\x1b\\");
		}
		return out.toString();
	}
}
