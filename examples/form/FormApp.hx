import cui.App;
import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.state.Binding;
import cui.state.State;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.HStack;
import cui.ui.Spacer;
import cui.ui.Button;
import cui.ui.Input;
import cui.ui.Checkbox;

class FormApp extends App {
    @:state var name:String = "";
    @:state var email:String = "";
    @:state var newsletter:Bool = true;
    @:state var terms:Bool = false;
    @:state var submitted:Bool = false;

    override public function body():View {
        if (submitted) {
            return new VStack([
                new Text("Form Submitted!")
                    .bold()
                    .foregroundColor(Color.Named(NamedColor.Green)),
                new Spacer(),
                new Text('Name:       $name'),
                new Text('Email:      $email'),
                new Text('Newsletter: ${newsletter ? "Yes" : "No"}'),
                new Text('Terms:      ${terms ? "Accepted" : "Not accepted"}'),
                new Spacer(),
                new Button("Back", () -> submitted = false),
            ], 1).padding(1).border(Rounded);
        }

        return new VStack([
            new Text("CUI Form Demo")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Cyan)),
            new Text("Tab: navigate | Enter/Space: toggle | Click: focus")
                .dim(),
            new Spacer(),
            new HStack([
                new Text("Name:  ").foregroundColor(Color.Named(NamedColor.Yellow)),
                new Input(Binding.from(name_), "Enter your name")
                    .border(Single),
            ], 0),
            new HStack([
                new Text("Email: ").foregroundColor(Color.Named(NamedColor.Yellow)),
                new Input(Binding.from(email_), "Enter your email")
                    .border(Single),
            ], 0),
            new Spacer(),
            new Checkbox("Subscribe to newsletter", CheckboxBinding.fromState(newsletter_)),
            new Checkbox("I accept the terms", CheckboxBinding.fromState(terms_)),
            new Spacer(),
            new HStack([
                new Spacer(),
                new Button("Submit", () -> submitted = true),
                new Spacer(),
                new Button("Clear", () -> {
                    name = "";
                    email = "";
                    newsletter = true;
                    terms = false;
                }),
                new Spacer(),
            ], 1),
            new Text("Ctrl+C to quit").dim(),
        ], 1).padding(1).border(Rounded);
    }

    static function main() {
        var app = new FormApp();
        app.run();
    }
}
