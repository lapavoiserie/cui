# Shared State Example

Demonstrates Observable for sharing state across multiple ViewComponents.

## Source

```haxe
// Shared state model
class CartState extends Observable {
    @:state public var itemCount:Int = 0;
    @:state public var total:Float = 0.0;
    public static var instance:CartState = new CartState();
}

// Component that displays the cart summary
class CartSummary extends ViewComponent {
    var cart:CartState;

    public function new(cart:CartState) {
        super();
        this.cart = cart;
    }

    override public function body():View {
        return new VStack([
            new Text("Cart Summary").bold().foregroundColor(Color.Named(NamedColor.Cyan)),
            new Text('Items: ${cart.itemCount}'),
            new Text('Total: ${cart.total}'),
            new ProgressBar(Math.min(1.0, cart.total / 100.0), "Budget"),
        ], 0).padding(1).border(Single);
    }
}

// Component with product buttons
class ProductList extends ViewComponent {
    var cart:CartState;

    public function new(cart:CartState) {
        super();
        this.cart = cart;
    }

    override public function body():View {
        return new VStack([
            new Text("Products").bold().foregroundColor(Color.Named(NamedColor.Green)),
            new HStack([
                new Button("Coffee $4.50", () -> {
                    cart.itemCount++;
                    cart.total = cart.total + 4.50;
                }),
                new Button("Sandwich $8.00", () -> { ... }),
                new Button("Juice $3.25", () -> { ... }),
            ], 1),
            new Button("Clear Cart", () -> {
                cart.itemCount = 0;
                cart.total = 0.0;
            }),
        ], 1).padding(1).border(Single);
    }
}

// App composes both components
class SharedStateApp extends App {
    var cart = CartState.instance;

    override public function body():View {
        return new VStack([
            new Text("CUI Shared State Demo").bold(),
            new HStack([
                cast(new ProductList(cart), View),
                cast(new CartSummary(cart), View),
            ], 1),
        ], 1).padding(1).border(Rounded);
    }
}
```

## Walkthrough

### Observable

`CartState` extends `Observable`, which supports `@:state` fields. Both `ProductList` and `CartSummary` receive the same `CartState` instance.

### Reactive Updates

When `ProductList` calls `cart.itemCount++`, the dirty flag is set. The event loop re-renders the entire UI, and `CartSummary` reads the updated value via `cart.itemCount`.

### ViewComponent

Both `ProductList` and `CartSummary` extend `ViewComponent` and override `body()`. They're composed in the main app just like any other view.

### cast(..., View)

```haxe
cast(new ProductList(cart), View)
```

This is needed because `ViewComponent` subclasses return their specific type, but VStack/HStack expect `Array<View>`.

## Run It

```bash
haxe build-shared-state.hxml
./bin-shared-state/SharedStateApp
```
