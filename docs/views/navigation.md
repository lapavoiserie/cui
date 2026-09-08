# Navigation

## Tabs

A tabbed container with a header bar and content switching.

```haxe
@:state var activeTab:Int = 0;

new Tabs([
    { label: "Overview", content: overviewView() },
    { label: "Details",  content: detailsView() },
    { label: "Settings", content: settingsView() },
], TabSelection.fromState(activeTab_))
    .border(Single)
```

**Constructor**: `new Tabs(tabs:Array<TabItem>, active:TabSelection)`

Where `TabItem` is:
```haxe
typedef TabItem = {
    label:String,
    content:View,
};
```

### Rendering

```
 Overview │ Details │ Settings
────────────────────────────────
 (active tab content here)
```

The active tab label is bold. When focused, it also shows with inverse colors. Inactive tabs are dimmed.

### Interaction

| Input | Action |
|-------|--------|
| Left arrow | Switch to previous tab |
| Right arrow | Switch to next tab |

### Tab Selection State

Like ListView, the active tab index is managed externally:

```haxe
@:state var activeTab:Int = 0;
var selection = TabSelection.fromState(activeTab_);
new Tabs(tabItems, selection)
```

See [Binding](../state/binding.md#tabselection) for details.
