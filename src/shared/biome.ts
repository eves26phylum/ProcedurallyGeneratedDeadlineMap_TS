import { WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
import { BiomeData, biomeExtension } from "./biomeExtension";
import { InstanceAdapter } from "./definition";
// !deadline-ts.customFinishSector_FinishModulesEnd

export interface Biome {
    priority: number
    name: string
    adapter: InstanceAdapter
}

export function useBiomeData(yourCell: WedgeCell): BiomeData | undefined {
  const data = biomeExtension.get(yourCell);
  if (!data) return;
  return data;
}

const defaultValue = {
    whoClaimedThis: []
};

export function biomeClaimLand(thisBiome: Biome, yourCell: WedgeCell): void {
  const data = biomeExtension.get(yourCell);
  if (!data) return;
  data.whoClaimedThis.push(thisBiome.name);
}

// If a cell might not have biome data yet but you want to guarantee it does by the time this function exits, getOrInit handles that without a separate has() check followed by a set()
export function ensureBiomeData(yourCell: WedgeCell): BiomeData {
  return biomeExtension.getOrInit(yourCell, () => (defaultValue));
}