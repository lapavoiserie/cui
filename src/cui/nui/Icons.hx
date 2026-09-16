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
class Icons {
	/** A combining long solidus overlay: the stroke of an `-off` name. **/
	public static inline var STROKE = "̸";

	/**
		Variation selector 15: "draw this one as text, not as an emoji".

		Several of these characters have two faces, and a terminal that picks
		the emoji one draws it **two cells wide and in colour** -- Windows
		Terminal does -- so the name beside the icon collides with it. Asking
		for the text face is what the selector is for, and a terminal with no
		emoji face for that character ignores it. It lives in the cell of the
		character it follows (`cui.render.Buffer`), so an icon is one cell
		whichever face is drawn.

		Found on Windows by the Farceur session: `settings`, `warning`, `mail`,
		`phone` and `person` came out wide and coloured.
	**/
	public static inline var AS_TEXT = "︎";

	/**
		**A character here is one a terminal draws in one narrow cell.**

		That is the whole constraint, and it is stricter than "a character that
		means the right thing": a terminal lays a panel out in cells, and one
		glyph drawn two cells wide shifts every name after it on that line.
		Windows Terminal draws several old symbols that way -- it has an emoji
		face for them and prefers it -- and `AS_TEXT` does not always stop it.

		So a name whose obvious picture is wide gets a plainer character that is
		narrow everywhere, and the vocabulary's names never change for it. Each
		candidate is measured in a terminal before it lands here: `mic` became a
		circle on a stand rather than a musical note, and `eye` a dotted circle,
		after the Farceur session measured them in Windows Terminal against a
		rule. An application that would rather have its own may set this map.
	**/

	public static final GLYPHS:Map<String, String> = [
		// general
		"add" => "+", "close" => "×", "check" => "✓", "delete" => "⌫",
		"edit" => "✎", "search" => "⌕", "settings" => "⚙" + AS_TEXT, "home" => "⌂",
		"info" => "ⓘ", "warning" => "⚠" + AS_TEXT, "error" => "⊗", "menu" => "≡",
		"more" => "…", "refresh" => "↻", "share" => "⇪", "star" => "★",
		"person" => "☺" + AS_TEXT, "lock" => "⚿", "unlock" => "⚷", "mail" => "✉" + AS_TEXT,
		"phone" => "☎" + AS_TEXT, "save" => "⇩",
		// direction
		"back" => "‹", "forward" => "›", "up" => "˄", "down" => "˅",
		// media
		"play" => "▶" + AS_TEXT, "pause" => "‖", "stop" => "■", "record" => "●",
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
