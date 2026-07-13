import { Ping, PingNoisePlayer, PingUIItem } from "./pingfactory";
import { deadlineAdapter } from "shared/deadlineAdapter";
import { adapterToUse } from "shared/adapterToUse";
import { Logger } from "shared/logger";

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
    function getRaycastOnCharacterLook(overrideCFrame?: CFrame, distance?: number) { // function only compatible with deadline
        const camera_cframe = overrideCFrame || framework.character.get_camera_cframe()
        const raycast_params = query.create_raycast_params();
        const DroneFolder = deadlineAdapter.findFirstChild(get_map_root(), "DronesFolder");
        if (!DroneFolder) return;
        raycast_params.filter_descendants_instances([ DroneFolder ]);
        raycast_params.filter_type(Enum.RaycastFilterType.Exclude);

        const origin = camera_cframe.Position
        const direction = camera_cframe.LookVector.mul(distance || 15000)

        const hit = query.raycast(origin, direction, raycast_params)

        if (!hit) return;
        return hit.position
    }
    const clientInputGroup = new ClientInputGroup();
    clientInputGroup.bind_user_setting(() => { // check
        const raycastPos = getRaycastOnCharacterLook()
        if (!raycastPos) return;
        fire_server(
            "ping_at_position",
            raycastPos
        )
    }, InputType.Ended, "lean_left")
    Log.info("Listening for ping requests from the server to display", "Listening for lean_left keybind pressed");
}