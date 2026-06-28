import { startMapGenerator } from "./map_generator";
import { kickStart } from "./ingame";
import { adapterToUse } from "shared/adapterToUse";
import { getWorldRoot } from "shared/getRoot";
import { loadPeoplesRepublicOfGermetistan } from "./loadPeoplesRepublicOfGermetistan";
import { isDeadline } from "shared/isDeadline";

const dogRef: {
    current?: number
} = {};
loadPeoplesRepublicOfGermetistan();
map.set_preset("afghanistan");
function connect() {
    let disconnectAll: void | (() => void);
    disconnectAll = kickStart(adapterToUse, getWorldRoot(), dogRef, (team_alive) => {
        if (!disconnectAll) return;
        disconnectAll();
        players.get_alive().forEach((player: Player) => {
            player.kill();
        })
        info(team_alive);
        connect();
    });
}
connect();
if (isDeadline) {
    sharedvars.sv_spawning_enabled = false;
    chat.set_spawning_disabled_reason("The map is generating. Please be patient.");
}
const maxHeight = startMapGenerator();
dogRef.current = maxHeight + 20;

if (isDeadline) sharedvars.sv_spawning_enabled = true;