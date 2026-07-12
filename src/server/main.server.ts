import { startMapGenerator } from "./map_generator";
import { kickStart } from "./ingame";
import { adapterToUse } from "shared/adapterToUse";
import { getWorldRoot } from "shared/getRoot";
import { loadPeoplesRepublicOfGermetistan } from "./loadPeoplesRepublicOfGermetistan";
import { isDeadline } from "shared/isDeadline";
import { Logger } from "shared/logger";

const Log = new Logger("main");

function loadMap() {
    // heavy operation
    if (!isDeadline) return;
    loadPeoplesRepublicOfGermetistan();
    map.set_preset("afghanistan");
    sharedvars.sv_spawning_enabled = false;
    chat.set_spawning_disabled_reason("The map is generating. Please be patient.");
    const maxHeight = startMapGenerator();
    dogRef.current = maxHeight + 20;
    sharedvars.sv_spawning_enabled = true;
}


const dogRef: {
    current?: number
} = {};
function connect() {
    let disconnectAll: void | (() => void);
    disconnectAll = kickStart(adapterToUse, getWorldRoot(), dogRef, (team_alive) => {
        if (!disconnectAll) return;
        disconnectAll();
        players.get_alive().forEach((player: Player) => {
            player.kill();
        })
        Log.info("someone won", team_alive);
        connect();
    });
}
//connect();

function initialise_game() {
    const Log = new Logger("main::initialise_game");
    Log.log("Starting map generation function");
    let terrain_generate_connection;
    if (isDeadline) {
        players.get_all().forEach((player: Player, index: number) => {
            player.fire_client("terrain_generate");
        })
        terrain_generate_connection = on_player_joined.Connect((name: string) => {
            const player = players.get(name);
            if (!player) return;
            player.fire_client("terrain_generate");
        })
    }
    loadMap();
    if (isDeadline) {
        players.get_all().forEach((player: Player, index: number) => {
            player.fire_client("terrain_finished");
        })
        on_player_joined.Connect((name: string) => {
            const player = players.get(name);
            if (!player) return;
            player.fire_client("terrain_finished");
        })
        on_player_spawned.Connect((name: string) => {
            const player = players.get(name);
            if (!player) return;
            player.fire_client("disconnect_iris");
        })
        terrain_generate_connection?.Disconnect();
    }
    Log.log("Map generation function has finished");
    Log.log("Starting ingame function");
    connect();
    Log.log("Ingame function has finished", "initialise_game has finished");
}
Shared.should_initialise_game = true;
on_client_event.Connect((playerName: string, args: unknown[]) => {
    const player = players.get(playerName);
    if (!player) return;
    const eventType = args[0];
    if (!typeIs(eventType, "string")) return player.kick();
    if (eventType !== "initialise_game") return;
    if (!Shared.should_initialise_game) {
        return player.fire_client("initialise", false);
    }
    Shared.should_initialise_game = false;
    player.fire_client("initialise", true);
    Log.log(playerName, "has started the initialisation function.")
    initialise_game();
})