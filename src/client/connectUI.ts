import { Logger } from "shared/logger";
export function connectUILogic() {
    const Log = new Logger("ui");
    class lookListener {
        irisConnection?: () => void
        private text: string
        private status1?: number
        private status2?: number
        windowSize: IrisState<Vector2>
        constructor() {
            this.windowSize = iris.State(new Vector2(500, 100));
            this.text = "Generating terrain. You cannot spawn until it is done generating.";
        }
        private renderThing() {
            iris.Window(["BIOME STATUS (DRAGGABLE WINDOW)"], {size: this.windowSize});
            if (this.status1) {
                iris.Text([`Building terrain heightmap... ${this.status1 * 100}%`]);
            }
            if (this.status2) {
                iris.Text([`Building structures... ${this.status2 * 100}%`]);
            }
            iris.Text([this.text]);
            iris.End();
        }
        kickStart() {
            this.irisConnection = iris.Connect(() => {this.renderThing()});
        }
        setText(text: string) {
            this.text = text;
        }
        setStatus1(number: number) {
            this.status1 = number;
        }
        setStatus2(number: number) {
            this.status2 = number;
        }
        disable() {
            this.irisConnection?.();
        }
    }
    const look = new lookListener();
    on_server_event.Connect((args: unknown[]) => {
        const eventType: unknown = args[0];
        assert(typeIs(eventType, "string"), "Event is not a string");
        if (eventType === "terrain_finished") {
            look.setText("Terrain has been generated. Feel free to spawn to get rid of this message.");
        }
        if (eventType === "terrain_generate") {
            look.disable(); // a hack for my bad code
            look.kickStart();
        }
        if (eventType === "disconnect_iris") {
            look.disable();
        }
        if (eventType === "biomeLoadingStatus_1") {
            const percentage: number | unknown = args[1];
            assert(typeIs(percentage, "number"), "percentage is not a number");
            look.setStatus1(percentage);
        }
        if (eventType === "biomeLoadingStatus_2") {
            const percentage: number | unknown = args[1];
            assert(typeIs(percentage, "number"), "percentage is not a number");
            look.setStatus2(percentage);
        }
        if (eventType === "initialise") {
            const isSuccessful: boolean | unknown = args[1];
            assert(typeIs(isSuccessful, "boolean"), "isSuccessful is not a boolean");
            Log[isSuccessful ? "info" : "warn"](isSuccessful ? "initialising game has been executed on the remote server" : "initialise game is not an available method");
        }
    })
    Log.info("Connected iris UI for displaying map generation status");
}