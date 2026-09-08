# Layout Views

## VStack

Arranges children vertically, top to bottom.

```haxe
new VStack([
    new Text("First"),
    new Text("Second"),
    new Text("Third"),
], 1)  // spacing = 1 row between children
```

**Constructor**: `new VStack(children:Array<View>, spacing:Int = 0)`

### Space Distribution

VStack uses a two-pass layout:

1. Measure each child's natural height
2. If total fits, use natural heights; Spacers absorb the remainder
3. If total overflows, compact children keep their size, greedy children split the rest equally

## HStack

Arranges children horizontally, left to right.

```haxe
new HStack([
    new Text("Left"),
    new Spacer(),
    new Text("Right"),
], 0)
```

**Constructor**: `new HStack(children:Array<View>, spacing:Int = 0)`

Uses the same two-pass distribution as VStack but along the horizontal axis.

## Box

A single-child container, useful for adding borders or background to any view.

```haxe
new Box(new Text("Content")).border(Rounded).padding(1)
```

**Constructor**: `new Box(?child:View)`

## Spacer

Fills all available space in its parent stack. Use multiple Spacers to distribute space evenly.

```haxe
new VStack([
    new Text("Top"),
    new Spacer(),        // pushes "Bottom" to the end
    new Text("Bottom"),
])
```

```haxe
new HStack([
    new Spacer(),
    new Text("Centered"),
    new Spacer(),
])
```

**Constructor**: `new Spacer()`

## Divider

A horizontal or vertical line separator.

```haxe
new Divider()                      // horizontal ─
new Divider(false)                 // vertical │
new Divider(true, "=")            // custom character
```

**Constructor**: `new Divider(horizontal:Bool = true, ?char:String)`

## ScrollView

Wraps content that may exceed the available space, providing vertical scrolling with a scrollbar.

```haxe
@:state var scrollPos:Int = 0;

new ScrollView(
    new VStack(longContent, 0),
    ScrollOffset.fromState(scrollPos_)
).border(Single)
```

**Constructor**: `new ScrollView(child:View, offset:ScrollOffset)`

The scroll offset is managed externally via `ScrollOffset` to persist across re-renders (same pattern as `ListSelection` and `TabSelection`).

### Interaction

| Input | Action |
|-------|--------|
| Up/Down arrows | Scroll one line |
| PageUp/PageDown | Scroll 10 lines |
| Mouse scroll wheel | Scroll 3 lines |

The scrollbar on the right edge shows position within the content. `█` marks the visible portion, `░` marks the rest.
