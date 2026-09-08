# Text & Labels

## Text

The most fundamental view. Displays styled text with automatic word wrapping.

```haxe
new Text("Hello, world!")
```

**Constructor**: `new Text(content:String)`

### Styling

```haxe
new Text("Important")
    .bold()
    .foregroundColor(Color.Named(NamedColor.Red))

new Text("Subtle hint").dim()

new Text("Centered Title")
    .bold()
    .alignment(Center)
```

### Word Wrapping

Text automatically wraps when it exceeds the available width:

```haxe
new Text("This is a very long sentence that will wrap to multiple lines when rendered in a narrow container.")
    .width(30)
```

### String Interpolation with State

Use Haxe string interpolation to display state values:

```haxe
@:state var count:Int = 0;

new Text('Count: $count')
```

The text updates automatically when the state changes because `body()` is called on every re-render.

### Alignment

| Value | Effect |
|-------|--------|
| `Left` | Left-aligned (default) |
| `Center` | Centered in available width |
| `Right` | Right-aligned |

```haxe
new Text("Centered").alignment(Center)
```
