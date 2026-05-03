import { AnyInstance, InstanceAdapter } from "shared/definition";
import { Logger } from "shared/logger";
import { isDeadline } from "shared/isDeadline";
import { SpectatorBox } from "shared/spectatorBoxBuilder";
// !deadline-ts.customFinishSector_FinishModulesEnd

const Log = new Logger("team_spawner"); // log, warn, info, error
export type lastSpawnType = {coordination: number} & Record<PlayerTeam, string[]>;
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
    const voicelines = {
        defender: [
            "Good morning, marines! We are waiting on %s marines to join us until we deploy.",
            "Remember what you're here for. We are waiting on %s marines to arrive here until we deploy.",
            "Don't mess up. We need %s more people. We gave you a lot more ammunition than you would normally get from your training in Complex."
        ],
        attacker: [
            "Defend the homeland. Wait for our remaining %s members.",
            "%s members until we teach this shitty government a lesson. Allah is greater.",
            "Let's go my brothers. %s more."
        ]
    }
    // const lastSpawnedPos: Partial<Record<PlayerTeam, Vector3>> = {};
    let offset = new Vector3(0, 3000, 0);
    const [firstPos, secondPos] = [new Vector3(-5000, 5000, -5000), new Vector3(5000, 5000, 5000)]
    on_player_spawned.Connect((name) => {
        time.wait(1.4)
        const player: Player | undefined = players.get(name);
        if (!player) return;
        const team: PlayerTeam = player.get_team();
        const thisSpectatorBox = spectatorBoxes[team] || new SpectatorBox(adapterToUse, offset, parent); // Get spectator box or create a new one if does not exist
        if (!spectatorBoxes[team]) {
            thisSpectatorBox.setSignText("Initialisation");
            offset = offset.add(new Vector3(200, 0, 0));
            spectatorBoxes[team] = thisSpectatorBox;
        }
        if (lastSpawns[team].indexOf(player.name) === -1) {
            lastSpawns[team].push(player.name);
            const thisVoicelineStr: string = voicelines[team][math.random(0, voicelines[team].size() - 1)];
            thisSpectatorBox.setSignText(string.format(thisVoicelineStr, `${lastSpawns.coordination - lastSpawns[team].size()}`));
        }
        player.set_position(spectatorBoxes[team].centerBoxPosition) // replace this with the spectator box pos

        lastSpawns[team].forEach((playerName: string, index: number) => { // Remove all players that left
            const thisPlayer = players.get(playerName);
            if (!thisPlayer) lastSpawns[team].remove(index);
        })

        if (lastSpawns[team].size() < lastSpawns.coordination) return;
        const raycast_params = query.create_raycast_params();
        const hit = query.raycast(new Vector3(math.random(firstPos.X, secondPos.X), math.random(firstPos.Y, secondPos.Y), math.random(firstPos.Z, secondPos.Z)), new Vector3(0, -15000, 0), raycast_params)
        if (!hit) {
            return Log.warn("Hit was not found when doing spawn logic");
        }
        
        const hitSpawnPos = hit.position.add(new Vector3(0, 26, 0));
        // lastSpawnedPos[team] = hitSpawnPos;
        
        Log.info(`Registering team spawn for the following members`, ...lastSpawns[team]);
        
        lastSpawns[team].forEach((playerName: string, index: number) => {
            const thisPlayer = players.get(playerName);
            if (!thisPlayer) return;
            thisPlayer.set_position(hitSpawnPos);
            task.delay(3, () => {
                thisPlayer.set_health(100);
            })
        })

        lastSpawns[team] = [];
        thisSpectatorBox.setSignText(`Zero`);
        // Log.info(`Player ${player.name} is arriving`);
        // Spawn this guy at a spectator box at Y level -200. You must separate spectator boxes for each team. Each wall in a spectator box is 3 studs thick (prevents penetration for rifles). When a spectator box spawns, it will spawn to the left of the last spectator box. Each spectator box is transparent and glass. The inside is filled with no collide water. There is a metal sign bolted to the middle of one of the walls that will say (if defender) `The mission will start when ${playersLeft} more SYNO arrive.`. If they're attacker, they will say `You will protect the homeland! ${playersLeft} players left until you will spawn`. The text resets in the HERE logic.
    });
}