class lookListener {
    irisConnection: () => void
    private text: string
    windowSize: IrisState<Vector2>
    constructor() {
        this.irisConnection = iris.Connect(() => {this.renderThing()});
        this.windowSize = iris.State(new Vector2(500, 100));
        this.text = "Generating terrain. You cannot spawn until it is done generating.";
    }
    private renderThing() {
        iris.Window(["BIOME STATUS (DRAGGABLE WINDOW)"], {size: this.windowSize});
        iris.Text([this.text]);
        iris.End();
    }
    setText(text: string) {
        this.text = text;
    }
    disable() {
        this.irisConnection();
    }
}
const look = new lookListener();
on_server_event.Connect((args: unknown[]) => {
    const eventType: unknown = args[0];
    assert(typeIs(eventType, "string"), "Event is not a string");
    if (eventType === "terrain_finished") {
        look.setText("Terrain has been generated. Feel free to spawn to get rid of this message.");
    }
    if (eventType === "disconnect_iris") {
        look.disable();
    }
})