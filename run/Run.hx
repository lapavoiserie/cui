import sys.FileSystem;
import sys.io.File;

class Run {
    static function main() {
        var args = Sys.args();
        // haxelib passes the CWD as the last argument
        var cwd = args.length > 0 ? args[args.length - 1] : Sys.getCwd();

        // Remove CWD from args
        if (args.length > 0) args.pop();

        if (args.length == 0) {
            printUsage();
            return;
        }

        switch (args[0]) {
            case "init":
                var appName = args.length > 1 ? args[1] : "MyApp";
                initProject(cwd, appName);
            case "build":
                buildProject(cwd);
            case "run":
                buildProject(cwd);
                runBinary(cwd);
            case "help":
                printUsage();
            default:
                Sys.println('Unknown command: ${args[0]}');
                printUsage();
        }
    }

    static function printUsage():Void {
        Sys.println("cui - Declarative TUI Framework for Haxe");
        Sys.println("");
        Sys.println("Usage:");
        Sys.println("  haxelib run cui init [AppName]  Create a new cui project");
        Sys.println("  haxelib run cui build            Compile build.hxml");
        Sys.println("  haxelib run cui run              Compile it, then run it");
        Sys.println("  haxelib run cui help             Show this help");
    }

    /**
        Compile the project.

        There is no pipeline here -- a terminal application is the binary Haxe
        produces, and nothing follows. `build` exists all the same, so that
        `mui build cui` can delegate to this CLI like it delegates to every
        other, instead of `mui` knowing that cui is the one that compiles
        straight.
    **/
    static function buildProject(cwd:String):Void {
        var hxml = sys.FileSystem.exists(cwd + "build-cui.hxml") ? "build-cui.hxml" : "build.hxml";
        if (!sys.FileSystem.exists(cwd + hxml)) {
            Sys.println('Error: $hxml not found in $cwd');
            Sys.exit(1);
        }
        Sys.setCwd(cwd);
        var code = Sys.command("haxe", [hxml]);
        if (code != 0) Sys.exit(code);
        Sys.println("Build complete: build/cui/");
    }

    /** Run what `build` produced, found by reading `-main` out of the hxml. **/
    static function runBinary(cwd:String):Void {
        var hxml = sys.FileSystem.exists(cwd + "build-cui.hxml") ? "build-cui.hxml" : "build.hxml";
        var main = null;
        for (line in File.getContent(cwd + hxml).split("\n")) {
            var trimmed = StringTools.trim(line);
            for (flag in ["-main ", "--main "])
                if (StringTools.startsWith(trimmed, flag))
                    main = StringTools.trim(trimmed.substr(flag.length));
        }
        if (main == null) {
            Sys.println("Error: no -main in " + hxml);
            Sys.exit(1);
        }
        var binary = cwd + "build/cui/" + main;
        if (!sys.FileSystem.exists(binary)) {
            Sys.println('Error: $binary not found');
            Sys.exit(1);
        }
        Sys.exit(Sys.command(binary));
    }

    static function initProject(cwd:String, appName:String):Void {
        Sys.println('Creating cui project: $appName');

        // Create directories
        var srcDir = cwd + "src/";
        if (!FileSystem.exists(srcDir)) FileSystem.createDirectory(srcDir);

        // Write build.hxml
        var buildContent = '-cp src\n-lib cui\n-main $appName\n-cpp bin\n';
        File.saveContent(cwd + "build.hxml", buildContent);
        Sys.println("  Created build.hxml");

        // Write main app file
        var appContent = 'import cui.App;
import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.Spacer;

class $appName extends App {
    @:state var count:Int = 0;

    override public function body():View {
        return new VStack([
            new Text("$appName")
                .bold()
                .foregroundColor(Color.Named(NamedColor.Cyan)),
            new Spacer(),
            new Text(\'Count: $${count.get()}\')
                .bold(),
            new Spacer(),
            new Text("+/-: change count | q: quit")
                .dim(),
        ], 0).padding(1).border(Rounded);
    }

    override public function handleEvent(event:Event):Bool {
        switch (event) {
            case Key(key):
                switch (key.code) {
                    case Char(c):
                        if (c == "+" || c == "=") { count.inc(); return true; }
                        if (c == "-") { count.dec(); return true; }
                        if (c == "q") { quit(); return true; }
                    default:
                }
            default:
        }
        return false;
    }

    static function main() {
        var app = new $appName();
        app.run();
    }
}
';
        File.saveContent(srcDir + appName + ".hx", appContent);
        Sys.println('  Created src/$appName.hx');

        // Write .gitignore
        File.saveContent(cwd + ".gitignore", "bin/\n.haxelib/\n");
        Sys.println("  Created .gitignore");

        Sys.println("");
        Sys.println("Done! To build and run:");
        Sys.println("  haxe build.hxml");
        Sys.println('  ./bin/$appName');
    }
}
