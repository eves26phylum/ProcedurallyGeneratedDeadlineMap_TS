import { AnyInstance, InstanceAdapter } from "shared/definition";
import { adapterToUse } from "shared/adapterToUse";
import { getWorldRoot } from "shared/getRoot";
import { droneMaterialConfig } from "shared/droneMaterialConfig";
import { assign } from "shared/Util";
import { Logger } from "shared/logger";

export function connectDroneLogic() {
    const Log = new Logger("drone");
    let [body_gyro, body_velocity, dronePart]: [AnyInstance<BodyGyro>?, AnyInstance<BodyVelocity>?, AnyInstance<BasePart>?] = [];
    on_server_event.Connect((args: unknown[]) => {
        const eventType: unknown = args[0];
        assert(typeIs(eventType, "string"), "Event is not a string");
        if (eventType === "player_ping") { // args[0]: event, args[1]: position, args[2]: drone name
            const drones = get_map_root().find_first_child("DronesFolder")
            if (!drones) return Log.warn("Failed to find drones folder");
            const drone_name = args[1];
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
            const [firstPos, secondPos] = [new Vector3(-5000, 5000, -5000), new Vector3(5000, 5000, 5000)]
            const raycast_params = query.create_raycast_params();
            const posToHitStartFrom = new Vector3(math.random(firstPos.X, secondPos.X), math.random(firstPos.Y, secondPos.Y), math.random(firstPos.Z, secondPos.Z));
            const hit = query.raycast(posToHitStartFrom, new Vector3(0, -15000, 0), raycast_params)
            if (!hit) {
                Log.error(`Hit was not found when doing drone spawn logic`, `Position from: ${posToHitStartFrom}`);
            }
            this.get_head_cframe = get_head_cframe;
            this.rot_x = 0;
            this.rot_y = 0;
            this.cam_position = new CFrame(hit?.position.add(new Vector3(0, 26, 0)) || new Vector3(0, 2000, 0));
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
                -this.input.movementX * 32,
                this.input.movementZ * 8,
                -this.input.movementY * 32
            ))

            // Lerp toward target so velocity builds and bleeds off like a real drone
            // Factor of 6 gives ~160ms ramp time; raise it for a snappier feel
            this.current_velocity = this.current_velocity.Lerp(target_velocity, math.min(1, delta_time * 3))
            body_velocity.Velocity = this.current_velocity

            this.camera_cframe = dronePart.CFrame.mul(new CFrame(0, 0, 0));
        }
    }
    register_camera_mode("DroneFreecam", DroneFreecam);

    Log.info("Registered DroneFreecam camera");
}