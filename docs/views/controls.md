# Controls

Interactive views that respond to keyboard and mouse input when focused.

## Button

A focusable element with a label and action callback.

```haxe
new Button("Save", () -> {
    // action when pressed
    saveData();
})
```

**Constructor**: `new Button(label:String, action:Void->Void)`

### Rendering

Buttons render as `[ label ]`. When focused, they display with inverse colors.

### Interaction

| Input | Action |
|-------|--------|
| Enter | Activate |
| Space | Activate |
| Mouse click | Focus + activate on next Enter/Space |

## Input

A focusable text input field with cursor, bound to a string state via `Binding`.

```haxe
@:state var name:String = "";

new Input(Binding.from(name_), "Enter your name")
    .border(Single)
```

**Constructor**: `new Input(binding:Binding<String>, placeholder:String = "")`

### Rendering

- Shows placeholder text (dimmed) when empty and not focused
- Shows text content with a blinking cursor (inverse cell) when focused
- Scrolls horizontally when text exceeds field width

### Interaction

| Input | Action |
|-------|--------|
| Characters | Insert at cursor |
| Backspace | Delete before cursor |
| Delete | Delete after cursor |
| Left/Right | Move cursor |
| Home | Move to start |
| End | Move to end |

### Binding

Input requires a `Binding<String>` to write back to the parent's state:

```haxe
@:state var email:String = "";

// Binding.from() creates a two-way binding from a State<String>
new Input(Binding.from(email_), "user@example.com")
```

See [Binding](../state/binding.md) for details.

## Checkbox

A focusable toggle with a label, bound to a boolean state via `CheckboxBinding`.

```haxe
@:state var agreed:Bool = false;

new Checkbox("I agree to the terms", CheckboxBinding.fromState(agreed_))
```

**Constructor**: `new Checkbox(label:String, binding:CheckboxBinding)`

### Rendering

```
[✓] Checked label
[ ] Unchecked label
```

When focused, the checkbox marker displays with inverse colors.

### Interaction

| Input | Action |
|-------|--------|
| Enter | Toggle |
| Space | Toggle |

## Slider

A horizontal slider rendered as a filled bar with a percentage label.

```haxe
@:state var volume:Float = 0.5;

new Slider(SliderBinding.fromState(volume_), 0.0, 1.0)
```

Renders as:

```
████████░░░░░░░░  50%
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| binding | `SliderBinding` | required | Two-way binding to a `FloatState` |
| min | `Float` | `0.0` | Minimum value |
| max | `Float` | `1.0` | Maximum value |
| step | `Float` | `0.05` | Increment per arrow key press |

### Interaction

| Input | Action |
|-------|--------|
| Right | Increase value by step |
| Left | Decrease value by step |

### SliderBinding

Create from a `FloatState`:

```haxe
SliderBinding.fromState(myFloatState)
```

Or manually with getter/setter:

```haxe
new SliderBinding(() -> getValue(), (v) -> setValue(v))
```
