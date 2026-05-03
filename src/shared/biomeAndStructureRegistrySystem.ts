import { Biome } from "./biome";
import { createTerrain, WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
import { Logger } from "./logger";
// !deadline-ts.customFinishSector_FinishModulesEnd
const thisLogger = new Logger("biomesAndStructures")
export interface modifierObject extends Biome {
    generate(yourSelf: createTerrain, yourCell: WedgeCell): void
}
export class biomeBox {
    modifiers: modifierObject[]
    constructor() {
        this.modifiers = [];
    }
    executeAllModifiers(yourSelf: createTerrain, yourCell: WedgeCell) {
        this.modifiers.forEach((modifier: modifierObject, index: number) => {
            modifier.generate(yourSelf, yourCell);
        })
    }
    registerModifier(yourObject: modifierObject) {
        thisLogger.info(`REGISTERED ${yourObject.name}`);
        this.modifiers.push(yourObject);
        this.modifiers.sort((a, b) => a.priority > b.priority);
    }
}