import cui.App;
import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.state.Binding;
import cui.state.State;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.HStack;
import cui.ui.Spacer;
import cui.ui.Button;
import cui.ui.Input;
import cui.ui.ListView;

class TodoApp extends App {
    @:state var inputText:String = "";
    @:state var selectedIdx:Int = 0;
    // Observable, so the view can be told when it changes -- and immutable, so
    // a change is a new value rather than a mutation nobody sees. Before, this
    // was a plain Array mutated in place and followed by StateBase.markDirty():
    // a manual refresh standing in for a dependency the framework could not see.
    @:state var todos:rui.structures.ImmutableList<String> =
        new rui.structures.ImmutableList(["Buy groceries", "Write documentation", "Review pull request"]);

    public function new() {
        super();
    }

    override public function body():View {
        var selection = ListSelection.fromState(selectedIdx);

        return new VStack([
            new Text("CUI Todo App")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Cyan)),
            new Text('${todos.value.length} items').dim(),
            new Spacer(),
            cast(new ListView(todos.value.toArray(), selection, null, (idx) -> {
                if (idx >= 0 && idx < todos.value.length) {
                    var kept = [for (i in 0...todos.value.length) if (i != idx) todos.value.get(i)];
                    todos.value = new rui.structures.ImmutableList(kept);
                    if (selectedIdx.get() >= todos.value.length && todos.value.length > 0) {
                        selectedIdx.set(todos.value.length - 1);
                    }
                }
            }), View)
                .border(Single)
                .foregroundColor(Color.Named(NamedColor.White)),
            new Spacer(),
            new HStack([
                new Text("New: ").foregroundColor(Color.Named(NamedColor.Yellow)),
                new Input(Binding.from(inputText), "Enter a todo...")
                    .border(Single),
            ], 0),
            new HStack([
                new Spacer(),
                new Button("Add", () -> {
                    var text = inputText.get();
                    if (text.length > 0) {
                        todos.value = todos.value.push(text);
                        inputText.set("");
                    }
                }),
                new Spacer(),
                new Button("Clear All", () -> {
                    // An empty list is a new value, so the view is told. The old
                    // line mutated in place and asked for a repaint by hand.
                    todos.value = new rui.structures.ImmutableList();
                    selectedIdx.set(0);
                }),
                new Spacer(),
            ], 1),
            new Text("Tab: navigate | \u2191\u2193: select | d: delete | Ctrl+C: quit")
                .dim(),
        ], 1).padding(1).border(Rounded);
    }

    static function main() {
        var app = new TodoApp();
        app.run();
    }
}
