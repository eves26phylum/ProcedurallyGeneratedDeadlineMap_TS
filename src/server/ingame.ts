import { AnyInstance, InstanceAdapter } from "shared/definition";
import { Logger } from "shared/logger";
import { isDeadline } from "shared/isDeadline";
import { SpectatorBox } from "shared/spectatorBoxBuilder";
import { voicelines } from "shared/voicelines";
// !deadline-ts.customFinishSector_FinishModulesEnd

const Log = new Logger("team_spawner"); // log, warn, info, error
export type lastSpawnType = {coordination: number} & Record<PlayerTeam, string[]>;
export function createDrone(player: Player, adapterToUse: InstanceAdapter, DroneFolder: AnyInstance<Folder>, random_drone_noise: string[]) {
    const player_name = player.name;

    const drone = adapterToUse.newInstance("Part");
    adapterToUse.setProperty(drone, "Size", new Vector3(1, 0.5, 2));
    adapterToUse.setProperty(drone, "Anchored", true);
    adapterToUse.setProperty(drone, "CanCollide", false);
    adapterToUse.setProperty(drone, "Transparency", 0.5);
    adapterToUse.setProperty(drone, "Name", player_name);
    adapterToUse.setProperty(drone, "CFrame", new CFrame());
    adapterToUse.setProperty(drone, "Position", new Vector3(0, 900.662, 0));
    adapterToUse.setProperty(drone, "Material", Enum.Material.Glass);
    adapterToUse.setProperty(drone, "Color", Color3.fromRGB(100, 100, 100));
    adapterToUse.addTag(drone, "glass_destructible");
    adapterToUse.setNetworkOwner(drone, player);
    adapterToUse.setProperty(drone, "Parent", DroneFolder);

    const body_gyro = adapterToUse.newInstance("BodyGyro");
    adapterToUse.setProperty(body_gyro, "MaxTorque", new Vector3(math.huge, math.huge, math.huge));
    adapterToUse.setProperty(body_gyro, "CFrame", drone.CFrame);
    adapterToUse.setProperty(body_gyro, "Name", "CoolGyro");
    adapterToUse.setProperty(body_gyro, "D", 500);
    adapterToUse.setProperty(body_gyro, "P", 3000);
    adapterToUse.setProperty(body_gyro, "Parent", drone);

    const body_velocity = adapterToUse.newInstance("BodyVelocity");
    adapterToUse.setProperty(body_velocity, "MaxForce", new Vector3(math.huge, math.huge, math.huge));
    adapterToUse.setProperty(body_velocity, "Velocity", new Vector3(0, 0, 0));
    adapterToUse.setProperty(body_velocity, "Name", "CoolVelocity");
    adapterToUse.setProperty(body_velocity, "P", 10000);
    adapterToUse.setProperty(body_velocity, "Parent", drone);

    const drone_noise = adapterToUse.newInstance("Sound");
    adapterToUse.setProperty(drone_noise, "Looped", true);
    adapterToUse.setProperty(drone_noise, "SoundId", random_drone_noise[math.random(0, random_drone_noise.size() - 1)]);
    adapterToUse.setProperty(drone_noise, "Volume", 1);
    adapterToUse.setProperty(drone_noise, "RollOffMaxDistance", 74);
    adapterToUse.setProperty(drone_noise, "Parent", drone);
    adapterToUse.playSound(drone_noise);

    player.fire_client("send_drone_info", player.name);
}
export function kickStart(adapterToUse: InstanceAdapter, parent: AnyInstance) {
    if (!isDeadline) return Log.info("Did not execute because the environment is not Deadline.");;
    Log.info("Listening for people spawning.");
    sharedvars.plr_ping_limit_sec = math.huge
    sharedvars.plr_ping_timeout_sec = math.huge
    sharedvars.plr_ping_warning_threshold_ms = math.huge
    sharedvars.ac_airtime_kill = false
    sharedvars.ac_movement = false
    sharedvars.ac_sound_kill = false
    sharedvars.plr_drum_magazines = 3
    sharedvars.plr_magazines = 9
    sharedvars.plr_spare_rounds = 90
    sharedvars.plr_base_weight = 1.7
    sharedvars.sv_gravity = 20
    sharedvars.plr_recoil = 0.5
    sharedvars.ff_field_voicelines = true
    map.set_time(10)
    const lastSpawns: lastSpawnType = {
        defender: [],
        attacker: [],
        coordination: 10
    }
    const spectatorBoxes: Record<PlayerTeam, SpectatorBox | undefined> = {
        defender: undefined,
        attacker: undefined
    }
    const ticketsLeft: Record<PlayerTeam, number> = {
        defender: 5,
        attacker: 5
    }
    const lastPingedTime: Record<string, number> = {}
    // const lastSpawnedPos: Partial<Record<PlayerTeam, Vector3>> = {};
    let offset = new Vector3(0, 3000, 0);
    const [firstPos, secondPos] = [new Vector3(-5000, 5000, -5000), new Vector3(5000, 5000, 5000)]
    const spawnedAmounts: Record<string, number> = {};
    on_player_spawned.Connect((name) => {
        const player: Player | undefined = players.get(name);
        if (!player || !player.is_alive()) return;
        const spawnedAmount = spawnedAmounts[player.name] !== undefined ? spawnedAmounts[player.name] + 1 : 0;
        spawnedAmounts[player.name] = spawnedAmount;
        time.wait(1.4);
        if (spawnedAmount !== spawnedAmounts[player.name]) return;
        const team: PlayerTeam = player.get_team();
        const thisSpectatorBox = spectatorBoxes[team] || new SpectatorBox(adapterToUse, offset, parent); // Get spectator box or create a new one if does not exist
        if (!spectatorBoxes[team]) {
            thisSpectatorBox.setSignText("*singing to myself*");
            offset = offset.add(new Vector3(200, 0, 0));
            spectatorBoxes[team] = thisSpectatorBox;
        }
        if (lastSpawns[team].indexOf(player.name) === -1) {
            lastSpawns[team].push(player.name);
        }
        player.set_position(spectatorBoxes[team].centerBoxPosition) // replace this with the spectator box pos
        player.set_camera_mode("Default");

        lastSpawns[team].forEach((playerName: string, index: number) => { // Remove all players that left
            const thisPlayer = players.get(playerName);
            if (!thisPlayer) lastSpawns[team].remove(index);
        })
        
        if (ticketsLeft[team] <= 0) {
            // SET FREE CAMERA
            
            player.set_custom_camera_mode("DroneFreecam");
            return;
        }
        const thisVoicelineStr: string = voicelines[team][math.random(0, voicelines[team].size() - 1)];
        thisSpectatorBox.setSignText(string.format(thisVoicelineStr, `${lastSpawns.coordination - lastSpawns[team].size()}`));
        if (lastSpawns[team].size() < lastSpawns.coordination) return;
        const raycast_params = query.create_raycast_params();
        const posToHitStartFrom = new Vector3(math.random(firstPos.X, secondPos.X), math.random(firstPos.Y, secondPos.Y), math.random(firstPos.Z, secondPos.Z));
        const hit = query.raycast(posToHitStartFrom, new Vector3(0, -15000, 0), raycast_params)
        if (!hit) {
            thisSpectatorBox.setSignText("We couldn't find a place to spawn. This is a mapping error, and please report it to the map developers.");
            return Log.warn(`Hit was not found when doing spawn logic`, `Position from: ${posToHitStartFrom}`);
        }
        
        const hitSpawnPos = hit.position.add(new Vector3(0, 26, 0));
        // lastSpawnedPos[team] = hitSpawnPos;
        
        Log.info(`Registering team spawn for the following members`, ...lastSpawns[team]);

        ticketsLeft[team] -= 1;
        
        lastSpawns[team].forEach((playerName: string, index: number) => {
            const thisPlayer = players.get(playerName);
            if (!thisPlayer) return;
            thisPlayer.set_position(hitSpawnPos);
            task.delay(3, () => {
                thisPlayer.set_health(100);
            })
        })

        lastSpawns[team] = [];
        thisSpectatorBox.setSignText(`Good luck on your mission.`);
        // Log.info(`Player ${player.name} is arriving`);
        // Spawn this guy at a spectator box at Y level -200. You must separate spectator boxes for each team. Each wall in a spectator box is 3 studs thick (prevents penetration for rifles). When a spectator box spawns, it will spawn to the left of the last spectator box. Each spectator box is transparent and glass. The inside is filled with no collide water. There is a metal sign bolted to the middle of one of the walls that will say (if defender) `The mission will start when ${playersLeft} more SYNO arrive.`. If they're attacker, they will say `You will protect the homeland! ${playersLeft} players left until you will spawn`. The text resets in the HERE logic.
    });
    on_player_died.Connect((name) => {
        const player: Player | undefined = players.get(name);
        if (!player) return;
        lastSpawns[player.get_team()].remove(lastSpawns[player.get_team()].indexOf(player.name));
    })
    on_player_left.Connect((name) => {
        const player: Player | undefined = players.get(name);
        if (!player) return;
        lastSpawns[player.get_team()].remove(lastSpawns[player.get_team()].indexOf(player.name));
    })
    on_client_event.Connect((player: Player, args: unknown[]) => {
        if (!player) return;
        const eventType = args[0];
        if (!typeIs(eventType, "string")) return player.kick();
        if (eventType === "ping_at_position") {
            const pingPosition = args[1];
            if (!typeIs(pingPosition, "Vector3")) return player.kick();
            if (os.time() - lastPingedTime[player.name] < 3) return;
            lastPingedTime[player.name] = os.time();
            players.get_all().forEach((thisPlayer: Player, index: number) => {
                thisPlayer.fire_client("player_ping", player.name);
                if (thisPlayer.get_team() !== player.get_team()) return;
                thisPlayer.fire_client("team_ping", pingPosition);
            })
        }
    })
}