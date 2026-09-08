# Counter

Demonstrates reactive state with `@:state`. The count updates in real time as you press keys.

## Source

```haxe
import cui.App;
import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.HStack;
import cui.ui.Spacer;

class CounterApp extends App {
    @:state var count:Int = 0;

    override public function body():View {
        return new VStack([
            new Text("CUI Counter Demo")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Cyan)),
            new Spacer(),
            new Text('Count: $count')
                .bold()
                .foregroundColor(
                    count > 0
                        ? Color.Named(NamedColor.Green)
                        : (count < 0 ? Color.Named(NamedColor.Red) : Color.Default)
                ),
            new Spacer(),
            new HStack([
                new Spacer(),
                new Text("[+] increment").foregroundColor(Color.Named(NamedColor.Green)),
                new Spacer(),
                new Text("[-] decrement").foregroundColor(Color.Named(NamedColor.Red)),
                new Spacer(),
                new Text("[r] reset").foregroundColor(Color.Named(NamedColor.Yellow)),
                new Spacer(),
            ], 0),
            new Text("[q] quit").dim(),
        ], 0).padding(1).border(Rounded);
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Char(c):
                        if (c == "+" || c == "=") { count++; return true; }
                        if (c == "-") { count--; return true; }
                        if (c == "r") { count = 0; return true; }
                        if (c == "q") { quit(); return true; }
                    default:
                }
            default:
        }
        return false;
    }

    static function main() {
        var app = new CounterApp();
        app.run();
    }
}
```

## Walkthrough

### @:state

```haxe
@:state var count:Int = 0;
```

The `StateMacro` turns this into an `IntState` cell, `count_`, and a property `count` over it at compile time. `count` reads and `count = …` writes; `count_.inc()`, `count_.dec()` and `count_.setTo()` are the cell's own.

### Reactive Color

The count text changes color based on value:
- Green when positive
- Red when negative
- Default when zero

This works because `body()` is called on every state change, re-evaluating the ternary expression.

### Diff Rendering

When you press `+`, only the digit cell changes — the framework diffs the buffers and emits a single cursor-move + character write.

## Run It

```bash
haxe build-counter.hxml
./bin-counter/CounterApp
```
