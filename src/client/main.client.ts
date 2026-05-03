class lookListener {
    irisConnection: RBXScriptConnection
    private text: string
    constructor() {
        this.irisConnection = iris.Connect(() => {this.renderThing()});
        this.text = "Generating terrain—cannot spawn.";
    }
    private renderThing() {
        iris.Window(["BIOME STATUS"]);
        iris.Text([this.text]);
        iris.End();
    }
    setText(text: string) {
        this.text = text;
    }
    disable() {
        this.irisConnection.Disconnect();
    }
}
const look = new lookListener();
on_server_event.Connect((args: unknown[]) => {
    const eventType: unknown = args[0];
    assert(typeIs(eventType, "string"), "Event is not a string");
    if (eventType === "disconnect_iris") {
        look.setText("Terrain has been generated. Feel free to spawn.");
    }
})
let thisConn: RBXScriptConnection | undefined
thisConn = framework.on_spawned.Connect(function() {
    look.disable();
    thisConn?.Disconnect();
})