import { createTerrain, WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
// !deadline-ts.customFinishSector_FinishModulesEnd
export interface modifierObject {
    priority: number
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
        this.modifiers.push(yourObject);
        this.modifiers.sort((a, b) => a.priority > b.priority);
    }
}