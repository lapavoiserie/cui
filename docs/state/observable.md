# Observable

Observable is a base class for shared state models. It supports `@:state` fields via `@:autoBuild`, just like `App` and `ViewComponent`.

## Defining a Model

```haxe
class CartState extends Observable {
    @:state public var itemCount:Int = 0;
    @:state public var total:Float = 0.0;

    public static var instance = new CartState();
}
```

Note: fields should be `public` so other components can access them.

## Using from Components

Any component can read and mutate the shared state:

```haxe
class CartSummary extends ViewComponent {
    var cart:CartState;

    public function new(cart:CartState) {
        super();
        this.cart = cart;
    }

    override public function body():View {
        return new Text('Items: ${cart.itemCount}');
    }
}

class ProductButton extends ViewComponent {
    var cart:CartState;

    public function new(cart:CartState) {
        super();
        this.cart = cart;
    }

    override public function body():View {
        return new Button("Add Item", () -> {
            cart.itemCount++;
            cart.total = cart.total + 9.99;
        });
    }
}
```

When `ProductButton` mutates `cart.itemCount`, the dirty flag is set and the entire UI re-renders — including `CartSummary`, which now reads the updated value.

## Singleton Pattern

A common pattern is to expose a singleton instance:

```haxe
class AppState extends Observable {
    @:state public var theme:String = "dark";
    @:state public var username:String = "Guest";

    public static var instance = new AppState();
}
```

Then access from anywhere:

```haxe
var state = AppState.instance;
new Text('Hello, ${state.username}');
```

## vs @:state on App

| | `@:state` on App | Observable |
|---|---|---|
| Scope | Single App class | Any number of components |
| Access | `this.fieldName` | Passed as constructor arg or singleton |
| Use when | Simple apps | Multi-component apps with shared data |
