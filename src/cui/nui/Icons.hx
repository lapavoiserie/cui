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
		"mic" => "♪", "mic-off" => "♪" + STROKE,
		"speaker" => "♫", "speaker-off" => "♫" + STROKE,
		"headphones" => "Ω",
		// visibility
		"eye" => "◎", "eye-off" => "◎" + STROKE,
		// things
		"folder" => "▤", "document" => "▯", "image" => "▣", "camera" => "◉",
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
