package cui.nui;

import cui.render.Color;
// `NamedColor` is a secondary type of that module, and `nui.Role` would be
// shadowed by `Color.Role` -- the enum constructor added for this very
// feature. Both named apart rather than left to luck.
import cui.render.Color.NamedColor;
import nui.Color as Wire;
import nui.Role as WireRole;

/**
	A `nui.Color` as a colour a terminal can draw, and back.

	## A role becomes one of the sixteen

	A terminal has sixteen colours, and they are the ones the person chose: the
	reds and blues of their own theme. So a role resolves to a **named** colour
	rather than to components, and a `danger` comes out in the red they picked.
	That is better than exact, not worse than it — `#DC2626` chosen on somebody
	else's machine would be a number that ignores everything this terminal
	knows.

	The role is kept as the word (`Color.Role`) until `cui.render.Style` emits
	the escape, so a relayed tree keeps its roles: a terminal that flattened one
	would send a number onward with nothing left to say it had ever been a role.

	## Components are exact where the terminal allows it

	`Rgb` emits a truecolor escape, so `#c8323c` arrives as itself on a terminal
	that supports one. **Opacity is dropped**: a cell is opaque, there is nothing
	to blend with, and a half-transparent red drawn solid is the closest honest
	answer.

	## What this corrected

	`cui` described a colour as `Std.string` of its enum value — literally
	`"Named(Red)"` on the wire — and the receiving side parsed only bare names
	like `"red"`. So a colour did not survive a round trip at all: it came back
	as nothing. Nobody had looked at a coloured tree crossing.
**/
class Colors {
	/** What a terminal draws for a colour the wire said. **/
	public static function resolve(said:Null<String>):Null<Color> {
		if (said == null) return null;

		var role = Wire.roleOf(said);
		if (role != null) return Color.Role((role : String));

		var parts = Wire.rgbOf(said);
		// A cell is opaque: there is nothing behind it to blend with.
		return parts == null ? null : Color.Rgb(parts.r, parts.g, parts.b);
	}

	/**
		The word for a colour this terminal holds, or null for none.

		`Default` is the terminal's own, which the wire has no way to name and
		no business naming: a receiver's default is its own affair.
	**/
	public static function say(colour:Null<Color>):Null<String> {
		if (colour == null) return null;
		return switch (colour) {
			case Role(name): WireRole.of(name) == null ? null : Wire.ROLE + name;
			case Rgb(r, g, b): (Wire.rgb(r, g, b) : String);
			case Named(c): (conventional(c) : String);
			case Indexed(_) | Default: null;
		}
	}

	/**
		The one of sixteen a role is drawn in.

		`surface` and `text` are the terminal's OWN background and foreground,
		so they would be `Default` — but a modifier asking for the default is a
		modifier asking for nothing, so they take the nearest deliberate choice
		instead: white on black is what a terminal already is.
	**/
	public static function named(role:Null<String>):NamedColor {
		return switch (WireRole.of(role)) {
			case Accent: BrightCyan;
			case Danger: BrightRed;
			case Warning: BrightYellow;
			case Success: BrightGreen;
			case Surface: Black;
			case Text: White;
			case Muted: BrightBlack;
			case Border: BrightBlack;
			case _: White;
		}
	}

	/**
		What one of the sixteen is, in components, for a tree leaving here.

		An approximation in the one direction it has to be: the wire has no way
		to say "the red this person chose", so it says a conventional red and the
		far side draws that. Documented rather than hidden — see `cui`'s page.
	**/
	static function conventional(c:NamedColor):Wire {
		return switch (c) {
			case Black: Wire.rgb(0, 0, 0);
			case Red: Wire.rgb(170, 0, 0);
			case Green: Wire.rgb(0, 170, 0);
			case Yellow: Wire.rgb(170, 85, 0);
			case Blue: Wire.rgb(0, 0, 170);
			case Magenta: Wire.rgb(170, 0, 170);
			case Cyan: Wire.rgb(0, 170, 170);
			case White: Wire.rgb(170, 170, 170);
			case BrightBlack: Wire.rgb(85, 85, 85);
			case BrightRed: Wire.rgb(255, 85, 85);
			case BrightGreen: Wire.rgb(85, 255, 85);
			case BrightYellow: Wire.rgb(255, 255, 85);
			case BrightBlue: Wire.rgb(85, 85, 255);
			case BrightMagenta: Wire.rgb(255, 85, 255);
			case BrightCyan: Wire.rgb(85, 255, 255);
			case BrightWhite: Wire.rgb(255, 255, 255);
		}
	}
}
