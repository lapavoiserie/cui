# Getting Started

## Requirements

- [Haxe](https://haxe.org/) 4.3+
- [hxcpp](https://lib.haxe.org/p/hxcpp/) (installed automatically as a dependency)

## Installation

```bash
haxelib git cui https://github.com/lapavoiserie/cui
```

## Create a Project

The fastest way to start is with the CLI:

```bash
haxelib run cui init MyApp
```

This generates:

```
myapp/
├── src/
│   └── MyApp.hx    # Your app with a counter template
├── build.hxml       # Build configuration
└── .gitignore
```

## Build and Run

```bash
haxe build.hxml
./bin/MyApp
```

This compiles your Haxe code to C++ via hxcpp, producing a native binary.

## Manual Setup

If you prefer to set up manually:

**build.hxml**:
```
-cp src
-lib cui
-main MyApp
-cpp bin
```

**src/MyApp.hx**:
```haxe
import cui.App;
import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.ui.Text;
import cui.ui.VStack;

class MyApp extends App {
    override public function body():View {
        return new VStack([
            new Text("Hello from cui!")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Cyan)),
            new Text("Press Ctrl+C to quit").dim(),
        ]).padding(1).border(Rounded);
    }

    static function main() {
        new MyApp().run();
    }
}
```

## App Lifecycle

Every cui app follows this structure:

1. Extend `App`
2. Override `body()` to return a `View` tree
3. Optionally override `handleEvent()` for keyboard input
4. Call `run()` from `main()`

```haxe
class MyApp extends App {
    override public function body():View {
        // Build your UI here — called on every render
    }

    override public function handleEvent(event:Event):Bool {
        // Handle keyboard events not consumed by focused views
        return false;
    }

    static function main() {
        new MyApp().run();
    }
}
```

The framework handles:
- Entering/leaving raw mode and alternate screen
- The render loop (build view tree -> layout -> render -> diff -> flush)
- Focus management (Tab/Shift-Tab)
- Mouse capture
- Clean exit on Ctrl+C

## Next Steps

- [Views](views/README.md) — Learn about the built-in views
- [Modifiers](modifiers.md) — Style and layout your views
- [State](state/README.md) — Add reactive state
- [Examples](examples/README.md) — Browse complete example apps
