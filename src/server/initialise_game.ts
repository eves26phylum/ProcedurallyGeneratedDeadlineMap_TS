import { makeDogRef } from "./initialiseDogRef";
import { loadMap } from "./loadMap";
import { connectIngameSystemsInALoop } from "./connectIngame";
import { isDeadline } from "shared/isDeadline";

export function initialise_game() {
    const dogRef = makeDogRef();
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
    loadMap(dogRef);
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
    connectIngameSystemsInALoop(dogRef);
}