package cui.nui;

/**
	The canon measures in points; this backend measures in character cells.

	Every other backend draws on a surface whose unit is the point, so that is
	what the canon's `spacing`, `padding`, `width` and `height` are — and they
	arrived here as if they were cells. `spacing={12}`, a fair gap between two
	rows of a form, became **twelve blank lines**; the kitchen sink's root
	stack then spent 92 of a 140-row terminal on its own spacing and padding,
	squeezed a group to 22 rows while its padding asked for 24, and that group
	drew nothing at all. Measured on 2026-09-21, and read at first as a
	rendering defect, which it was not.

	## The cell

	A cell is taken to be **8 points wide and 16 points tall**, the ratio of a
	terminal font at an ordinary size. It is a convention, not a measurement:
	nothing here can ask the terminal how big its glyphs are, and a number that
	cannot be measured is better written down once than guessed at four call
	sites.

	Rounding is to the nearest cell, so a gap of 8 points is one row rather
	than none: a designer who asked for space gets some. Below half a cell it
	rounds away, which is the honest answer — a terminal has nothing smaller.
	A length is never negative here.
**/
class Units {
	/** How wide a cell is, in points. **/
	public static inline var CELL_WIDTH = 8.0;

	/** How tall a cell is, in points. **/
	public static inline var CELL_HEIGHT = 16.0;

	/** Points to rows, down the screen. **/
	public static function rows(points:Float):Int {
		return cells(points, CELL_HEIGHT);
	}

	/** Points to columns, across the screen. **/
	public static function columns(points:Float):Int {
		return cells(points, CELL_WIDTH);
	}

	/** Rows back to points, for describing this backend's own tree. **/
	public static function pointsFromRows(rows:Int):Float {
		return rows * CELL_HEIGHT;
	}

	/** Columns back to points. **/
	public static function pointsFromColumns(columns:Int):Float {
		return columns * CELL_WIDTH;
	}

	static function cells(points:Float, size:Float):Int {
		if (points <= 0 || Math.isNaN(points)) return 0;
		var n = Math.round(points / size);
		return n < 0 ? 0 : n;
	}
}
