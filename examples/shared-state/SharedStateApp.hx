import cui.App;
import cui.View;
import cui.ViewComponent;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.state.Observable;
import cui.state.State;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.HStack;
import cui.ui.Spacer;
import cui.ui.Button;
import cui.ui.ProgressBar;

// Shared state model — accessible from any component
class CartState extends Observable {
    @:state public var itemCount:Int = 0;
    @:state public var total:Float = 0.0;

    public static var instance:CartState = new CartState();
}

// A component that displays the cart summary
class CartSummary extends ViewComponent {
    var cart:CartState;

    public function new(cart:CartState) {
        super();
        this.cart = cart;
    }

    override public function body():View {
        var count = cart.itemCount;
        var totalStr = Std.string(Std.int(cart.total * 100) / 100);
        return new VStack([
            new Text("Cart Summary")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Cyan)),
            new Text('Items: $count'),
            new Text('Total: $totalStr'),
            new ProgressBar(Math.min(1.0, cart.total / 100.0), "Budget"),
        ], 0).padding(1).border(Single);
    }
}

// A component that shows product buttons
class ProductList extends ViewComponent {
    var cart:CartState;

    public function new(cart:CartState) {
        super();
        this.cart = cart;
    }

    override public function body():View {
        return new VStack([
            new Text("Products")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Green)),
            new HStack([
                new Button("Coffee $4.50", () -> {
                    cart.itemCount++;
                    cart.total = cart.total + 4.50;
                }),
                new Button("Sandwich $8.00", () -> {
                    cart.itemCount++;
                    cart.total = cart.total + 8.00;
                }),
                new Button("Juice $3.25", () -> {
                    cart.itemCount++;
                    cart.total = cart.total + 3.25;
                }),
            ], 1),
            new Button("Clear Cart", () -> {
                cart.itemCount = 0;
                cart.total = 0.0;
            }).foregroundColor(Color.Named(NamedColor.Red)),
        ], 1).padding(1).border(Single);
    }
}

class SharedStateApp extends App {
    var cart:CartState;

    public function new() {
        super();
        cart = CartState.instance;
    }

    override public function body():View {
        // Both components read from the same CartState
        // When ProductList mutates it, CartSummary updates automatically
        return new VStack([
            new Text("CUI Shared State Demo")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Cyan)),
            new Text("Observable state shared across ViewComponents")
                .dim(),
            new Spacer(),
            new HStack([
                cast(new ProductList(cart), View),
                cast(new CartSummary(cart), View),
            ], 1),
            new Spacer(),
            new Text("Tab: navigate | Enter/Space: add to cart | Ctrl+C: quit")
                .dim(),
        ], 1).padding(1).border(Rounded);
    }

    static function main() {
        var app = new SharedStateApp();
        app.run();
    }
}
