package cui.nui;

/**
	The shared vocabulary (`nui.Icons`) as characters.

	A terminal has one cell per icon, so each name is one character wide -- not
	a picture, a sign. They are read by whatever font the terminal uses, which
	is why every one of them is an old, widely cut character rather than an
	emoji: an emoji is two cells wide in some terminals and a blank box in
	others, and either wrecks a line of a panel.

	An `-off` name is its base with a stroke through it, as nui's vocabulary
	says: the base character followed by a combining long solidus, which the
	terminal draws in the same cell.
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
		- **The terminal advances one cell and paints over the next** -- which is
		  what Windows Terminal does with `settings`, `warning`, `mail` and
		  `phone`, having an emoji face for them and preferring it. The cursor is
		  where cui thinks it is, but the name beside the icon disappears under
		  the picture: `Inked`, which reserves a blank cell after it.

		Elsewhere -- a terminal drawing these monochrome in one cell -- a
		reserved cell is one space, which costs a panel nothing and is why this
		is not conditioned on which terminal is running.

		Benjamin chose colour over compactness here: "les autres icônes ne sont
		pas assez visibles". So a name keeps the character that is drawn as a
		picture, and the layout makes room for it.
	**/
	public static final ROOM:Map<String, Room> = [
		"settings" => Inked, "warning" => Inked, "mail" => Inked, "phone" => Inked,
		"delete" => Inked,
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
		"add" => "+", "close" => "×", "check" => "✓", "delete" => "⌫",
		"edit" => "✎", "search" => "⌕", "settings" => "⚙", "home" => "⌂",
		"info" => "ⓘ", "warning" => "⚠", "error" => "⊗", "menu" => "≡",
		"more" => "…", "refresh" => "↻", "share" => "⇪", "star" => "★",
		"person" => "☺", "lock" => "⚿", "unlock" => "⚷", "mail" => "✉",
		"phone" => "☎", "save" => "⇩",
		// direction
		"back" => "‹", "forward" => "›", "up" => "˄", "down" => "˅",
		// media
		"play" => "▶", "pause" => "‖", "stop" => "■", "record" => "●",
		"swap" => "⇄", "broadcast" => "⦿",
		"mic" => "⚲", "mic-off" => "⚲" + STROKE,
		"speaker" => "♫", "speaker-off" => "♫" + STROKE,
		"headphones" => "Ω",
		// visibility
		"eye" => "ʘ", "eye-off" => "ʘ" + STROKE,
		// things
		"folder" => "▤", "document" => "▯", "image" => "▣", "camera" => "⊡",
		"video" => "▷", "clock" => "◷", "display" => "▭", "window" => "▢",
		"globe" => "◍", "text" => "T", "palette" => "◐", "grid" => "▦",
		// arranging
		"layers" => "≣", "bring-front" => "⤒", "send-back" => "⤓",
		"crop" => "⌗", "move" => "✥", "rotate" => "⟲",
	];

	/** The character for a name, or null when this vocabulary has none. **/
	public static function glyphOf(name:String):Null<String>
		return name == null ? null : GLYPHS.get(name);
}
