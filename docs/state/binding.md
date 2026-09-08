# Binding

Bindings provide two-way state passing between parent and child views. When the child writes to the binding, the parent's state updates and triggers a re-render.

## Binding\<T>

Used by `Input` to write text back to the parent's state.

```haxe
@:state var name:String = "";

new Input(Binding.from(name_), "Enter name")
```

### Creating Bindings

```haxe
// From a State<T>
Binding.from(myState)

// Custom getter/setter
new Binding(
    () -> getValue(),
    (v) -> setValue(v)
)
```

## CheckboxBinding

Used by `Checkbox` to toggle a boolean state.

```haxe
@:state var agreed:Bool = false;

new Checkbox("I agree", CheckboxBinding.fromState(agreed_))
```

### Creating CheckboxBindings

```haxe
// From a BoolState
CheckboxBinding.fromState(myBoolState)

// Custom
new CheckboxBinding(
    () -> getChecked(),
    (v) -> setChecked(v)
)
```

## ListSelection

Used by `ListView` to track the selected index.

```haxe
@:state var idx:Int = 0;

new ListView(items, ListSelection.fromState(idx_))
```

### Why External Selection?

Since `body()` creates new view instances on every render, internal state like `selectedIndex` would reset to 0. By storing selection in the parent's `@:state`, it persists across re-renders.

### Creating ListSelections

```haxe
// From an IntState
ListSelection.fromState(myIntState)

// Custom
new ListSelection(
    () -> getIndex(),
    (v) -> setIndex(v)
)
```

## TabSelection

Used by `Tabs` to track the active tab index.

```haxe
@:state var activeTab:Int = 0;

new Tabs(tabItems, TabSelection.fromState(activeTab_))
```

### Creating TabSelections

```haxe
// From an IntState
TabSelection.fromState(myIntState)

// Custom
new TabSelection(
    () -> getTab(),
    (v) -> setTab(v)
)
```

## Pattern Summary

| View | Binding type | State type |
|------|-------------|------------|
| Input | `Binding<String>` | `StringState` |
| Checkbox | `CheckboxBinding` | `BoolState` |
| ListView | `ListSelection` | `IntState` |
| Tabs | `TabSelection` | `IntState` |
