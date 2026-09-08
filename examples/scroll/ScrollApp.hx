import cui.App;
import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.HStack;
import cui.ui.Spacer;
import cui.ui.ScrollView;
import cui.state.State;

class ScrollApp extends App {
    @:state var scrollPos:Int = 0;

    override public function body():View {
        // Build a long content that exceeds terminal height
        var lines = new Array<View>();
        var topics = [
            { title: "Getting Started", color: NamedColor.Cyan, lines: [
                "cui is a declarative TUI framework for Haxe.",
                "It lets you build terminal apps with composable",
                "views, chainable modifiers, and reactive state.",
                "",
                "Install with: haxelib git cui ...",
                "Create a project: haxelib run cui init MyApp",
            ]},
            { title: "Views", color: NamedColor.Green, lines: [
                "Text     - styled text with word wrapping",
                "VStack   - vertical layout with spacing",
                "HStack   - horizontal layout with spacing",
                "Box      - container with optional border",
                "Spacer   - flexible space filler",
                "Divider  - horizontal or vertical line",
                "Button   - activatable element",
                "Input    - text input field with cursor",
                "Checkbox - toggle with label",
                "ListView - scrollable list with selection",
                "Table    - tabular data display",
                "ProgressBar - progress indicator",
                "Tabs     - tab navigation",
                "ForEach  - data-driven repetition",
                "ScrollView - scrollable content wrapper",
            ]},
            { title: "Modifiers", color: NamedColor.Yellow, lines: [
                ".bold()            - bold text",
                ".italic()          - italic text",
                ".underline()       - underlined text",
                ".dim()             - dim/faded text",
                ".foregroundColor() - text color",
                ".backgroundColor() - background color",
                ".padding()         - inner spacing",
                ".border()          - box border",
                ".width()           - fixed width",
                ".alignment()       - text alignment",
            ]},
            { title: "State Management", color: NamedColor.Magenta, lines: [
                "@:state var count:Int = 0;",
                "  count.get()  - read value",
                "  count.set(5) - write value",
                "  count.inc()  - increment",
                "  count.dec()  - decrement",
                "",
                "@:state var name:String = \"\";",
                "  name.get()     - read value",
                "  name.set(\"x\") - write value",
                "  name.append()  - append text",
                "",
                "@:state var ok:Bool = false;",
                "  ok.toggle() - flip value",
            ]},
        ];

        for (topic in topics) {
            lines.push(
                new Text(topic.title)
                    .bold()
                    .foregroundColor(Color.Named(topic.color))
            );
            lines.push(new Text(""));
            for (line in topic.lines) {
                lines.push(new Text("  " + line));
            }
            lines.push(new Text(""));
        }

        return new VStack([
            new HStack([
                new Text(" CUI Documentation ")
                    .bold()
                    .foregroundColor(Color.Named(NamedColor.Cyan)),
                new Spacer(),
                new Text("\u2191\u2193/scroll: navigate | Ctrl+C: quit ")
                    .dim(),
            ], 0),
            cast(new ScrollView(
                new VStack(lines, 0),
                ScrollOffset.fromState(scrollPos_)
            ), View).border(Single),
        ], 0).padding(1).border(Rounded);
    }

    static function main() {
        var app = new ScrollApp();
        app.run();
    }
}
