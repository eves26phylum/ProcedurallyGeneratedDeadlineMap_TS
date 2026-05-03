import { WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
import { BiomeData, structureExtension } from "./biomeExtension";
import { Biome } from "./biome";
// !deadline-ts.customFinishSector_FinishModulesEnd

export function useStructureData(yourCell: WedgeCell): BiomeData | undefined {
  const data = structureExtension.get(yourCell);
  if (!data) return;
  return data;
}

export function structureClaimLand(thisBiome: Biome, yourCell: WedgeCell): void {
  const data = structureExtension.get(yourCell);
  if (!data) return;
  data.whoClaimedThis.push(thisBiome.name);
}

// If a cell might not have biome data yet but you want to guarantee it does by the time this function exits, getOrInit handles that without a separate has() check followed by a set()
export function ensureStructureData(yourCell: WedgeCell): BiomeData {
  return structureExtension.getOrInit(yourCell, () => ({
      whoClaimedThis: []
  }));
}