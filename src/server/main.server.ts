import { startMapGenerator } from "./map_generator";
import { kickStart } from "./ingame";
import { adapterToUse } from "shared/adapterToUse";
import { getWorldRoot } from "shared/getRoot";
import { loadPeoplesRepublicOfGermetistan } from "./loadPeoplesRepublicOfGermetistan";

const dogRef: {
    current?: number
} = {};
loadPeoplesRepublicOfGermetistan();
map.set_preset("afghanistan");
kickStart(adapterToUse, getWorldRoot(), dogRef);
const maxHeight = startMapGenerator();
dogRef.current = maxHeight + 20;