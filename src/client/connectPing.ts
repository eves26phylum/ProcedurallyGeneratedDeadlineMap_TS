import { Ping, PingNoisePlayer, PingUIItem } from "./pingfactory";
import { deadlineAdapter } from "shared/deadlineAdapter";
import { adapterToUse } from "shared/adapterToUse";
import { Logger } from "shared/logger";
import { getRaycast } from "./getRaycast";

export function connectPingLogic() {
    const pingFactory = new Ping(new PingUIItem(adapterToUse), new PingNoisePlayer(adapterToUse), 10)
    const Log = new Logger("ping");
    on_server_event.Connect((args: unknown[]) => {
        const eventType: unknown = args[0];
        assert(typeIs(eventType, "string"), "Event is not a string");
        if (eventType === "team_ping") {
            const pingPosition = args[1];
            assert(typeIs(pingPosition, "vector"), "Ping position is not a Vector3");
            pingFactory.play(pingPosition);
        }
    })
    const clientInputGroup = new ClientInputGroup();
    clientInputGroup.bind_user_setting(() => { // check
        const DroneFolder = deadlineAdapter.findFirstChild(get_map_root(), "DronesFolder");
        if (!DroneFolder) return;
        const raycastPos = getRaycast(framework.character.get_camera_cframe(), 15000, [ DroneFolder ])?.position
        if (!raycastPos) return;
        fire_server(
            "ping_at_position",
            raycastPos
        )
    }, InputType.Ended, "lean_left")
    Log.info("Listening for ping requests from the server to display", "Listening for lean_left keybind pressed");
}