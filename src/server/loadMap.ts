import { startMapGenerator } from "./map_generator";
import { loadPeoplesRepublicOfGermetistan } from "./loadPeoplesRepublicOfGermetistan";
import { isDeadline } from "shared/isDeadline";
import { dogRefType } from "./initialiseDogRef";
export function loadMap(dogRef: dogRefType) {
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