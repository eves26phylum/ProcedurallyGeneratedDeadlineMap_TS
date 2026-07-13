import { kickStart } from "./ingame";
import { adapterToUse } from "shared/adapterToUse";
import { getWorldRoot } from "shared/getRoot";
import { dogRefType } from "./initialiseDogRef";
import { Logger } from "shared/logger";
export function connectIngameSystemsInALoop(dogRef: dogRefType) {
    const Log = new Logger("in_game_systems_in_a_loop");
    let disconnectAll: void | (() => void);
    disconnectAll = kickStart(adapterToUse, getWorldRoot(), dogRef, (team_alive) => {
        if (!disconnectAll) return;
        disconnectAll();
        players.get_alive().forEach((player: Player) => {
            player.kill();
        })
        Log.info("someone won", team_alive);
        connectIngameSystemsInALoop(dogRef);
    });
    Log.info("I am now starting the game cycle.")
}