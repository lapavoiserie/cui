import cui.App;
import cui.View;
import cui.event.Event;
import cui.event.KeyEvent;
import cui.render.Color;
import cui.render.BorderStyle;
import cui.state.State;
import cui.ui.Text;
import cui.ui.VStack;
import cui.ui.HStack;
import cui.ui.Spacer;
import cui.ui.Tabs;
import cui.ui.Table;
import cui.ui.ProgressBar;
import cui.ui.ListView;

class DashboardApp extends App {
    @:state var activeTab:Int = 0;
    @:state var logIdx:Int = 0;

    override public function body():View {
        return new VStack([
            new HStack([
                new Text(" CUI Dashboard ")
                    .bold()
                    .foregroundColor(Color.Named(NamedColor.Cyan)),
                new Spacer(),
                new Text("\u2190\u2192: tabs | \u2191\u2193: list | Ctrl+C: quit ")
                    .dim(),
            ], 0),
            cast(Tabs.of([
                { label: "Overview", content: overviewTab() },
                { label: "Services", content: servicesTab() },
                { label: "Logs", content: logsTab() },
            ], TabSelection.fromState(activeTab_)), View)
                .border(Single),
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
            new Table(
                ["Metric", "Value", "Status"],
                [
                    ["Uptime", "14d 3h 22m", "OK"],
                    ["Requests/s", "1,247", "OK"],
                    ["Latency p99", "142ms", "WARN"],
                    ["Error rate", "0.03%", "OK"],
                ]
            ),
        ], 1);
    }

    function servicesTab():View {
        return new Table(
            ["Service", "Status", "Instances", "CPU", "Memory"],
            [
                ["api-gateway", "Running", "3/3", "23%", "512MB"],
                ["auth-service", "Running", "2/2", "8%", "256MB"],
                ["data-pipeline", "Degraded", "1/3", "95%", "1.2GB"],
                ["cache-layer", "Running", "4/4", "12%", "2.0GB"],
                ["worker-pool", "Running", "5/5", "67%", "890MB"],
                ["notification", "Stopped", "0/2", "0%", "0MB"],
            ]
        );
    }

    function logsTab():View {
        var logs = [
            "[INFO]  api-gateway: Health check passed",
            "[INFO]  auth-service: Token refreshed for user_42",
            "[WARN]  data-pipeline: Queue depth exceeding threshold (1024)",
            "[ERROR] data-pipeline: Worker 2 crashed, restarting...",
            "[INFO]  data-pipeline: Worker 2 restarted successfully",
            "[INFO]  cache-layer: Cache hit ratio: 94.2%",
            "[WARN]  notification: Connection pool exhausted, retrying",
            "[ERROR] notification: Service unreachable, marking as stopped",
            "[INFO]  worker-pool: Batch job #4521 completed (2.3s)",
            "[INFO]  api-gateway: 200 GET /api/v1/users (12ms)",
        ];

        return cast(new ListView(
            logs,
            ListSelection.fromState(logIdx_)
        ), View).foregroundColor(Color.Named(NamedColor.White));
    }

    static function main() {
        var app = new DashboardApp();
        app.run();
    }
}
