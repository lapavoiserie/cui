# Todo App

A functional todo list with add, delete, and keyboard navigation.

## Source

```haxe
class TodoApp extends App {
    @:state var inputText:String = "";
    @:state var selectedIdx:Int = 0;
    var todos:Array<String>;

    public function new() {
        super();
        todos = ["Buy groceries", "Write documentation", "Review pull request"];
    }

    override public function body():View {
        var selection = ListSelection.fromState(selectedIdx_);

        return new VStack([
            new Text("CUI Todo App").bold().foregroundColor(Color.Named(NamedColor.Cyan)),
            new Text('${todos.length} items').dim(),
            new Spacer(),
            cast(new ListView(todos, selection, null, (idx) -> {
                if (idx >= 0 && idx < todos.length) {
                    todos.splice(idx, 1);
                    if (selectedIdx >= todos.length && todos.length > 0)
                        selectedIdx = todos.length - 1;
                    StateBase.markDirty();
                }
            }), View).border(Single).foregroundColor(Color.Named(NamedColor.White)),
            new Spacer(),
            new HStack([
                new Text("New: ").foregroundColor(Color.Named(NamedColor.Yellow)),
                new Input(Binding.from(inputText_), "Enter a todo...").border(Single),
            ], 0),
            new HStack([
                new Spacer(),
                new Button("Add", () -> {
                    var text = inputText;
                    if (text.length > 0) { todos.push(text); inputText = ""; }
                }),
                new Spacer(),
                new Button("Clear All", () -> {
                    todos.splice(0, todos.length);
                    selectedIdx = 0;
                    StateBase.markDirty();
                }),
                new Spacer(),
            ], 1),
            new Text("Tab: navigate | Up/Down: select | d: delete | Ctrl+C: quit").dim(),
        ], 1).padding(1).border(Rounded);
    }
}
```

## Walkthrough

### Non-State Data + markDirty()

`todos` is a regular `Array<String>`, not `@:state`. After mutating it (splice, push), we call `StateBase.markDirty()` to trigger a re-render. Alternatively, mutating any `@:state` field (like `inputText = ""`) also triggers a re-render.

### ListView + ListSelection

```haxe
var selection = ListSelection.fromState(selectedIdx_);
new ListView(todos, selection, null, onDelete)
```

The selection index is stored as `@:state var selectedIdx:Int` so it persists across re-renders.

### Delete Callback

The `onDelete` callback receives the selected index. After splicing, it adjusts `selectedIdx` if it would be out of bounds.

## Run It

```bash
haxe build-todo.hxml
./bin-todo/TodoApp
```
