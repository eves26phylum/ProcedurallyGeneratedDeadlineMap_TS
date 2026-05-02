import { WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
import { CellExtension, createCellExtension } from "./cellExtension";
// !deadline-ts.customFinishSector_FinishModulesEnd
export interface BiomeData {
  whoClaimedThis: string[];
}

export const biomeExtension: CellExtension<WedgeCell, BiomeData> = createCellExtension<WedgeCell, BiomeData>();
export const structureExtension: CellExtension<WedgeCell, BiomeData> = createCellExtension<WedgeCell, BiomeData>();

// idk structure data goes here
// omg typescript is so new to me wtf is a weak map ohh okay i understand oh my gosh im stuck in a pizza traffic
// export const structureExtension = createCellExtension<WedgeCell, StructureData>();