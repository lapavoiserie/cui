package cui.nui;

/**
	The two directions, as two maps the build writes.

	Empty in the source and filled by `cui.nui.Derive` from what the controls
	declare. `BUILDERS` is keyed by node type; `DESCRIBERS` by the exact class
	path, so a caller walks up the superclass chain and the nearest declared
	ancestor wins.
**/
@:build(cui.nui.Derive.build())
class Derived {}
