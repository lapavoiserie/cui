package cui.ui;

import cui.View;
import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

/**
	Empty space that pushes.

	A TYPE the containers recognise, rather than a view with a weight:
	`VStack` and `HStack` look for it by name and hand every spacer an equal
	share of what is left. `pui`'s is a view like any other whose `flex`
	happens to be one, which is why a button can push there and only a spacer
	can push here.

	Declared with no properties for that reason. The canon's `flex` is real and
	this backend has nowhere to put it: two spacers here always push equally,
	and markup asking for `flex={2}` is refused rather than quietly ignored.
**/
@:node("Spacer")
class Spacer extends View {
    public function new() {
        super();
    }

    override public function measure(constraint:Constraint):Size {
        // Spacer wants to fill all available space
        return switch (constraint) {
            case Exact(w, h): new Size(w, h);
            case AtMost(w, h): new Size(w, h);
            case Unbounded: new Size(0, 0);
        };
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        // Spacer renders nothing — it just takes up space
    }
}
