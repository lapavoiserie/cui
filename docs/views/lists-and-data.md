# Lists & Data

Views for displaying collections and data.

## ListView

A scrollable list with keyboard selection and optional scroll indicator.

```haxe
@:state var selectedIdx:Int = 0;

new ListView(
    items,
    ListSelection.fromState(selectedIdx_),
    (idx) -> onSelect(idx),   // onSelect callback
    (idx) -> onDelete(idx)    // onDelete callback
).border(Single)
```

**Constructor**: `new ListView(items:Array<String>, selection:ListSelection, ?onSelect:Int->Void, ?onDelete:Int->Void)`

### Rendering

```
> Selected item         (inverse when focused)
  Regular item
  Another item
                        ██ (scrollbar)
                        ░░
```

### Interaction

| Input | Action |
|-------|--------|
| Up/Down | Move selection |
| Enter | Trigger onSelect callback |
| Delete or `d` | Trigger onDelete callback |

### Selection State

Selection is managed externally via `ListSelection` to survive re-renders:

```haxe
@:state var idx:Int = 0;
var selection = ListSelection.fromState(idx_);
new ListView(items, selection)
```

See [Binding](../state/binding.md#listselection) for details.

## Table

Displays tabular data with auto-sized columns, bold headers, and separators.

```haxe
new Table(
    ["Name", "Role", "Status"],
    [
        ["Alice", "Engineer", "Active"],
        ["Bob", "Designer", "Away"],
    ]
)
```

**Constructor**: `new Table(headers:Array<String>, rows:Array<Array<String>>)`

### Rendering

```
 Name  │ Role     │ Status
───────┼──────────┼───────
 Alice │ Engineer │ Active
 Bob   │ Designer │ Away
```

Column widths are computed from the widest cell in each column.

## ProgressBar

A progress indicator using Unicode block characters for sub-cell precision.

```haxe
new ProgressBar(0.73, "CPU")
```

**Constructor**: `new ProgressBar(value:Float, label:String = "")`

- `value`: 0.0 to 1.0
- `label`: optional prefix

### Rendering

```
CPU ████████████▎░░░░░ 73%
```

Uses 8 levels of block characters (▏▎▍▌▋▊▉█) for smooth progress indication.

## ForEach

Maps an array of data to views. Similar to `Array.map()` but produces a vertical layout.

```haxe
new ForEach(users, (user) -> {
    return new Text(user.name)
        .foregroundColor(Color.Named(NamedColor.Green));
}, 1)  // spacing between items
```

**Constructor**: `new ForEach<T>(items:Array<T>, builder:T->View, spacing:Int = 0)`
