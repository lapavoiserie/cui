# Dashboard

A multi-tab dashboard showcasing Tabs, Table, ProgressBar, and ListView together.

## Source

```haxe
class DashboardApp extends App {
    @:state var activeTab:Int = 0;
    @:state var logIdx:Int = 0;

    override public function body():View {
        return new VStack([
            new HStack([
                new Text(" CUI Dashboard ").bold().foregroundColor(Color.Named(NamedColor.Cyan)),
                new Spacer(),
                new Text("Left/Right: tabs | Up/Down: list | Ctrl+C: quit ").dim(),
            ], 0),
            cast(new Tabs([
                { label: "Overview", content: overviewTab() },
                { label: "Services", content: servicesTab() },
                { label: "Logs",     content: logsTab() },
            ], TabSelection.fromState(activeTab_)), View).border(Single),
        ], 0).padding(1).border(Rounded);
    }

    function overviewTab():View {
        return new VStack([
            new Text("System Status").bold(),
            new Spacer(),
            new HStack([
                new VStack([
                    new Text("CPU").foregroundColor(Color.Named(NamedColor.Yellow)),
                    new ProgressBar(0.73, ""),
                ], 0).border(Single).padding(0, 1, 0, 1),
                new VStack([
                    new Text("Memory").foregroundColor(Color.Named(NamedColor.Yellow)),
                    new ProgressBar(0.45, ""),
                ], 0).border(Single).padding(0, 1, 0, 1),
                new VStack([
                    new Text("Disk").foregroundColor(Color.Named(NamedColor.Yellow)),
                    new ProgressBar(0.89, ""),
                ], 0).border(Single).padding(0, 1, 0, 1),
            ], 1),
            new Spacer(),
            new Table(["Metric", "Value", "Status"], [
                ["Uptime", "14d 3h 22m", "OK"],
                ["Requests/s", "1,247", "OK"],
                ["Latency p99", "142ms", "WARN"],
                ["Error rate", "0.03%", "OK"],
            ]),
        ], 1);
    }
    // ... servicesTab() and logsTab() ...
}
```

## Walkthrough

### Tabs

```haxe
new Tabs(tabItems, TabSelection.fromState(activeTab_))
```

Left/Right arrows switch tabs. Each tab has its own content view.

### HStack Space Distribution

The three progress bar panels share width equally thanks to the two-pass layout:
1. Each panel measures to full width (greedy)
2. HStack detects overflow and splits available space equally

### Table

```haxe
new Table(headers, rows)
```

Column widths are auto-calculated from the widest cell in each column.

### ProgressBar

```haxe
new ProgressBar(0.73, "")
```

Uses Unicode block characters (▏▎▍▌▋▊▉█) for sub-cell precision.

## Run It

```bash
haxe build-dashboard.hxml
./bin-dashboard/DashboardApp
```
