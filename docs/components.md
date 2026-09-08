# Components

`ViewComponent` is the base class for creating reusable custom views. It works just like `App` — override `body()` to return a view tree, and use `@:state` for local state.

## Defining a Component

```haxe
class InfoCard extends ViewComponent {
    var title:String;
    var content:String;

    public function new(title:String, content:String) {
        super();
        this.title = title;
        this.content = content;
    }

    override public function body():View {
        return new VStack([
            new Text(title).bold(),
            new Text(content),
        ], 0).padding(1).border(Rounded);
    }
}
```

## Using a Component

Components are views, so you compose them like any other:

```haxe
override public function body():View {
    return new VStack([
        cast(new InfoCard("Status", "All systems operational"), View),
        cast(new InfoCard("Uptime", "14 days"), View),
    ], 1);
}
```

The `cast(..., View)` is needed when chaining modifiers on a ViewComponent, since modifiers return `View`.

## Component State

Components support `@:state` for local state:

```haxe
class TogglePanel extends ViewComponent {
    @:state var expanded:Bool = false;
    var title:String;
    var content:View;

    public function new(title:String, content:View) {
        super();
        this.title = title;
        this.content = content;
    }

    override public function body():View {
        var arrow = expanded ? "\u25BC" : "\u25B6";
        var views:Array<View> = [
            new Button('$arrow $title', () -> expanded = !expanded),
        ];
        if (expanded) {
            views.push(content);
        }
        return new VStack(views, 0);
    }
}
```

## Component vs App

| | App | ViewComponent |
|---|-----|---------------|
| Entry point | Yes (`run()`, `main()`) | No |
| `body()` | Returns root view tree | Returns component's view tree |
| `@:state` | Supported | Supported |
| `handleEvent()` | App-level event handler | Not available |
| Usage | One per application | As many as needed |

## Shared State

For data shared across multiple components, use [Observable](state/observable.md) rather than passing state through constructor chains.
