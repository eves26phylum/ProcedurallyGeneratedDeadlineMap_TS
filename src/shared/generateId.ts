import { getRandomItemInArray } from "./getRandomItemInArray";
// !deadline-ts.customFinishSector_FinishModulesEnd

export function generateId(length: number, charMap: string[]) {
    let result: string = "";

    for (let i = 0; i < length; i++) {
        result = result + getRandomItemInArray(charMap);
    }

    return result;
}