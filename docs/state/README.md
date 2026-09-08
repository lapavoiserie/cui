# State Management

cui uses a reactive state system inspired by SwiftUI's `@State`. When state changes, the UI automatically re-renders.

## Overview

```haxe
class MyApp extends App {
    @:state var count:Int = 0;

    override public function body():View {
        return new Text('Count: $count');
    }
}
```

### How It Works

1. `@:state` fields are transformed at compile time by `StateMacro` into `State<T>` wrappers
2. When you write the field — `count = 1`, `count++` — a global dirty flag is set
3. The event loop detects the dirty flag and calls `body()` again
4. The new view tree is rendered into a buffer and diffed against the previous frame
5. Only changed cells are written to the terminal

This is an **immediate-mode** approach — `body()` is a pure function of state, called on every change. The diff-based renderer makes this efficient.

## State Types

| Original Type | Transformed To | Extra Methods |
|--------------|---------------|---------------|
| `Int` | `IntState` | `.inc()`, `.dec()` |
| `Float` | `FloatState` | `.inc()`, `.dec()` |
| `Bool` | `BoolState` | `.toggle()` |
| `String` | `StringState` | `.append()`, `.clear()` |
| Other | `State<T>` | (base methods only) |

The field itself is a property: `count` reads, `count = v` writes. The cell behind it, `count_`, shares across all state types: `.get()`, `.set(value)`, `.value`, `.peek()`, `.name` (read-only), `.setTo(value)`, `.toString()`

## What backs it

`State` extends [`rui.state.State`](https://lapavoiserie.github.io/rui/#/state), the
reactive core shared with the other La Pavoiserie backends (`sui`, `aui`, `wui`, `qui`).
A read inside a `rui` effect tracks it and a write notifies it — cui itself does not use
effects, it redraws from a dirty flag, which a write now raises through the shared sink.

Two consequences worth knowing:

- **A write with an unchanged value is a no-op.** `count = 5` when `count` is already
  `5` no longer schedules a redraw. Nothing is lost — there was nothing to draw.
- **`.applyExternal(value)`** writes without raising the dirty flag, for a value that came
  *from* the display and is therefore already on screen.

## Where State Lives

| Scope | Mechanism | Details |
|-------|-----------|---------|
| Single App | `@:state` on `App` | [State & Actions](state-and-actions.md) |
| Single Component | `@:state` on `ViewComponent` | [Components](../components.md) |
| Shared across components | `Observable` subclass | [Observable](observable.md) |
| Passed to child views | `Binding`, `ListSelection`, etc. | [Binding](binding.md) |

## Next Steps

- [State & Actions](state-and-actions.md) — Declaring and mutating state
- [Binding](binding.md) — Two-way state passing
- [Observable](observable.md) — Shared state models
