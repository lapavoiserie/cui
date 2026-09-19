package cui;

import cui.layout.Constraint;
import cui.layout.Rect;
import cui.layout.Size;
import cui.render.Buffer;

@:autoBuild(cui.macros.StateMacro.build())
class ViewComponent extends View {
    public function new() {
        super();
    }

    public function body():View {
        return new View();
    }

    override public function measure(constraint:Constraint):Size {
        return body().measure(constraint);
    }

    override public function render(buffer:Buffer, area:Rect):Void {
        body().renderInto(buffer, area);
    }
}
