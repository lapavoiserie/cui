package cui.nui;

/**
	The shared vocabulary (`nui.Icons`) as characters.

	A terminal has one cell per icon, so each name is one character wide -- not
	a picture, a sign. They are read by whatever font the terminal uses, which
	is why every one of them is an old, widely cut character rather than an
	emoji: an emoji is two cells wide in some terminals and a blank box in
	others, and either wrecks a line of a panel.

	An `-off` name is its base with a stroke through it -- the base character
	followed by a combining long solidus, which the terminal draws in the same
	cell -- unless it has a character of its own, as `speaker-off` does.

	Two names stay plain characters, by exception: `move` and `grid`, for which
	nothing coloured reads as what they mean -- the arrows are drawn
	monochrome and the squares look like squares. `menu`, `more`, the four
	directions and a few others are plain too, being signs rather than things.
**/
enum Room {
	/** One cell, drawn inside it. **/
	One;

	/** One cell for the cursor, two for the ink: a blank cell follows it. **/
	Inked;

	/** Two cells: the terminal advances over both. **/
	Wide;
}

class Icons {
	/** A combining long solidus overlay: the stroke of an `-off` name. **/
	public static inline var STROKE = "̸";

	/**
		How much room a character asks for, beyond the cell it is written in.

		Measured in a terminal, not derived from a property: the Farceur session
		put every candidate beside a rule in Windows Terminal and read off what
		happened. Two things can happen, and they are not the same thing.

		- **The terminal advances two cells** -- a real emoji, and a CJK
		  ideograph later. The cell after belongs to the character, and nothing
		  may write there: `Wide`, which `Buffer.setWide` marks.
		- **The terminal advances one cell and paints over the next.** The cursor
		  is where cui thinks it is, but the name beside the icon disappears
		  under the picture: `Inked`, which reserves a blank cell after it.

		  No name in this table is `Inked` any more, and the reason is worth
		  keeping: `settings`, `warning`, `mail` and `phone` were, until each was
		  written with U+FE0F after it. That selector asks for the coloured face,
		  and with it Windows Terminal advances two cells like any emoji;
		  without it, it paints one cell's character over two. So an application
		  writing `⚙` in its own text, selector-less, falls into that case, and
		  `Inked` is what its own table would say.

		Elsewhere -- a terminal drawing these monochrome in one cell -- a
		reserved cell is one space, which costs a panel nothing and is why this
		is not conditioned on which terminal is running.

		Benjamin chose colour over compactness here: "les autres icônes ne sont
		pas assez visibles". So a name keeps the character that is drawn as a
		picture, and the layout makes room for it.
	**/
	public static final ROOM:Map<String, Room> = [
		// The terminal advances two cells, and the ink stays inside them: every
		// picture in this table, since the last four were measured with their
		// selector. Nothing here is `Inked` any more -- see `Room` for what
		// that case is still for.
		"settings" => Wide, "warning" => Wide, "mail" => Wide, "phone" => Wide,
		"add" => Wide, "close" => Wide, "check" => Wide, "edit" => Wide, "search" => Wide,
		"home" => Wide, "info" => Wide, "error" => Wide, "refresh" => Wide, "share" => Wide,
		"star" => Wide, "person" => Wide, "lock" => Wide, "unlock" => Wide, "save" => Wide,
		"pause" => Wide, "stop" => Wide, "record" => Wide, "swap" => Wide, "broadcast" => Wide,
		"mic" => Wide, "speaker" => Wide, "speaker-off" => Wide, "headphones" => Wide,
		"folder" => Wide, "document" => Wide, "camera" => Wide, "video" => Wide,
		"clock" => Wide, "globe" => Wide, "palette" => Wide, "crop" => Wide,
		"delete" => Wide, "eye" => Wide, "eye-off" => Wide, "mic-off" => Wide,
		"image" => Wide, "display" => Wide, "window" => Wide, "text" => Wide,
		"rotate" => Wide, "bring-front" => Wide, "send-back" => Wide,
		// Drawn monochrome in the fonts measured, and kept anyway: it is the
		// right sign, and the face a font gives it is the font's business.
		"play" => Wide,
	];

	/** How much room this name's character takes, in cells. **/
	public static function cellsOf(name:String):Int
		return roomOf(name) == One ? 1 : 2;

	public static function roomOf(name:String):Room {
		var room = ROOM.get(name);
		return room == null ? One : room;
	}

	public static final GLYPHS:Map<String, String> = [
		// general
		"add" => "➕", "close" => "❌", "check" => "✅", "delete" => "🗑️",
		"edit" => "✏️", "search" => "🔍", "settings" => "⚙️", "home" => "🏠",
		"info" => "ℹ️", "warning" => "⚠️", "error" => "⛔", "menu" => "≡",
		"more" => "…", "refresh" => "🔄", "share" => "📤", "star" => "⭐",
		"person" => "👤", "lock" => "🔒", "unlock" => "🔓", "mail" => "✉️",
		"phone" => "☎️", "save" => "💾",
		// direction
		"back" => "‹", "forward" => "›", "up" => "˄", "down" => "˅",
		// media
		"play" => "▶️", "pause" => "⏸️", "stop" => "⏹️", "record" => "⏺️",
		"swap" => "🔀", "broadcast" => "📡",
		"mic" => "🎤", "mic-off" => "🤐",
		"speaker" => "🔊", "speaker-off" => "🔇",
		"headphones" => "🎧",
		// visibility
		"eye" => "👁️", "eye-off" => "🙈",
		// things
		"folder" => "📁", "document" => "📄", "image" => "🖼️", "camera" => "📷",
		"video" => "🎬", "clock" => "🕐", "display" => "🖥️", "window" => "🪟",
		"globe" => "🌐", "text" => "🔤", "palette" => "🎨", "grid" => "▦",
		// arranging
		"layers" => "≣", "bring-front" => "⏫", "send-back" => "⏬",
		"crop" => "✂️", "move" => "✥", "rotate" => "🔃",
	];

	/** The character for a name, or null when this vocabulary has none. **/
	public static function glyphOf(name:String):Null<String>
		return name == null ? null : GLYPHS.get(name);
}
