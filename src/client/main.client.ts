import { deadlineAdapter } from "shared/deadlineAdapter";
import { AnyInstance, InstanceAdapter } from "shared/definition";
import { droneMaterialConfig } from "shared/droneMaterialConfig";
import { isDeadline } from "shared/isDeadline";
import { Logger } from "shared/logger";
import { robloxAdapter } from "shared/robloxAdapter";
import { assign } from "shared/Util";
// !deadline-ts.customFinishSector_FinishModulesEnd
const adapterToUse: InstanceAdapter = isDeadline ? deadlineAdapter : robloxAdapter;
const Log = new Logger("main");
class lookListener {
    irisConnection: () => void
    private text: string
    windowSize: IrisState<Vector2>
    constructor() {
        this.windowSize = iris.State(new Vector2(500, 100));
        this.irisConnection = iris.Connect(() => {this.renderThing()});
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
let [body_gyro, body_velocity, dronePart]: [AnyInstance<BodyGyro>?, AnyInstance<BodyVelocity>?, AnyInstance<BasePart>?] = [];
on_server_event.Connect((args: unknown[]) => {
    const eventType: unknown = args[0];
    assert(typeIs(eventType, "string"), "Event is not a string");
    if (eventType === "terrain_finished") {
        look.setText("Terrain has been generated. Feel free to spawn to get rid of this message.");
    }
    if (eventType === "disconnect_iris") {
        look.disable();
    }
    if (eventType === "player_ping") {
        createPing(event_data.position)
        const drones = get_map_root().find_first_child("DronesFolder")
        if (!drones) return Log.warn("Failed to find drones folder");
        const drone_name = args[2];
        assert(typeIs(drone_name, "string"), "Drone name is not a string");
        const drone = adapterToUse.findFirstChild(drones, drone_name);
        assert(drone && adapterToUse.isA(drone, "BasePart"), "drone does not exist or is not a BasePart");
        adapterToUse.setProperty(drone, "Color", Color3.fromRGB(255, 255, 255))
        adapterToUse.setProperty(drone, "Material", Enum.Material.SmoothPlastic)
        assign(drone, droneMaterialConfig.selected, adapterToUse.setProperty);
        task.delay(0.2, () => {
            assign(drone, droneMaterialConfig.normal, adapterToUse.setProperty);
        })
    }
    if (eventType === "send_drone_info") {
        const drones = get_map_root().find_first_child("DronesFolder");
        if (!drones) return Log.warn("Failed to find drones folder");
        const drone_name = args[1];
        assert(typeIs(drone_name, "string"), "Drone name is not a string");
        const drone = adapterToUse.findFirstChild(drones, drone_name);
        if (!drone) return Log.warn(`Failed to find drone of ${drone_name}`);
        const bodyGyroCanidate = adapterToUse.findFirstChild(drone, "CoolGyro");
        const bodyVelocityCanidate = adapterToUse.findFirstChild(drone, "CoolVelocity");
        assert(bodyGyroCanidate && adapterToUse.isA(bodyGyroCanidate, "BodyGyro"), "CoolGyro does not exist or is not a BodyGyro");
        assert(bodyVelocityCanidate && adapterToUse.isA(bodyVelocityCanidate, "BodyVelocity"), "CoolVelocity does not exist or is not a BodyVelocity");
        assert(drone && adapterToUse.isA(drone, "BasePart"), "drone does not exist or is not a BasePart");
        body_gyro = bodyGyroCanidate;
        body_velocity = bodyVelocityCanidate;
        dronePart = drone;
        dronePart.CanCollide = true;
    }
})

class DroneFreecam {
    get_head_cframe: () => CFrame;
    rot_x: number;
    rot_y: number;
    cam_position: CFrame;
    min_roll: number;
    max_roll: number;
    input: CameraControllerMovementInputType;
    current_velocity: Vector3;
    camera_cframe: CFrame
    constructor(get_head_cframe: () => CFrame) {
        this.get_head_cframe = get_head_cframe;
        this.rot_x = 0;
        this.rot_y = 0;
        this.cam_position = new CFrame();
        this.min_roll = -math.pi / 2 + 0.2;
        this.max_roll = math.pi / 2 - 0.2;
        this.current_velocity = Vector3.zero;
        this.input = {
            movementX: 0,
            movementY: 0,
            movementZ: 0
        };
        this.camera_cframe = new CFrame();
    }
    update(delta_time: number) {
        if (!body_gyro || !body_velocity || !dronePart) return;
        const mouse_delta = input.get_mouse_delta().mul(0.1).mul(input.get_mouse_sensitivity())
        this.rot_y -= mouse_delta.Y
        this.rot_y  = math.clamp(this.rot_y, this.min_roll, this.max_roll)
        this.rot_x -= mouse_delta.X

        const full_cframe = CFrame.Angles(0, this.rot_x, 0).mul(CFrame.Angles(this.rot_y, 0, 0))
        body_gyro.CFrame = full_cframe

        const target_velocity = full_cframe.VectorToWorldSpace(new Vector3(
            -this.input.movementX * 16,
            this.input.movementZ * 4,
            -this.input.movementY * 16
        ))

        // Lerp toward target so velocity builds and bleeds off like a real drone
        // Factor of 6 gives ~160ms ramp time; raise it for a snappier feel
        this.current_velocity = this.current_velocity.Lerp(target_velocity, math.min(1, delta_time * 3))
        body_velocity.Velocity = this.current_velocity

        this.camera_cframe = dronePart.CFrame.mul(new CFrame(0, 0, 0));
    }
}
// class DroneFreecamFactory {
//     constructor(body_gyro: AnyInstance<BodyGyro>, body_velocity: AnyInstance<BodyVelocity>, drone_part: AnyInstance<BasePart>) {
//         return class {
//             constructor(get_head_cframe: () => CFrame) { 
//                 return new DroneFreecam(get_head_cframe, body_gyro, body_velocity, drone_part);
//             }
//         }
//     }
// }
register_camera_mode("DroneFreecam", DroneFreecam);
// function CustomFreecam:update(delta_time)
// 	if not body_gyro     then return end
// 	if not body_velocity then return end
// 	if not dronePart     then return end

// 	local mouse_delta = input.get_mouse_delta() * 0.1 * input.get_mouse_sensitivity()
// 	self.rot_y -= mouse_delta.Y
// 	self.rot_y  = math.clamp(self.rot_y, self.min_roll, self.max_roll)
// 	self.rot_x -= mouse_delta.X

// 	local full_cframe = CFrame.Angles(0, self.rot_x, 0) * CFrame.Angles(self.rot_y, 0, 0)
// 	body_gyro.CFrame = full_cframe

// 	local target_velocity = full_cframe:VectorToWorldSpace(Vector3.new(
// 		-self.input.movementX * 16,  -- Sideways
// 		 self.input.movementZ * 4,   -- Y
// 		-self.input.movementY * 16   -- Forward
// 	))

// 	-- Lerp toward target so velocity builds and bleeds off like a real drone
// 	-- Factor of 6 gives ~160ms ramp time; raise it for a snappier feel
// 	self.current_velocity = self.current_velocity:Lerp(target_velocity, math.min(1, delta_time * 3))
// 	body_velocity.Velocity = self.current_velocity

// 	self.camera_cframe = dronePart.CFrame * CFrame.new(0, 0, 0)
// end

// -- can also use Default to overwrite default cameramode
// register_camera_mode("Freecam", CustomFreecam)