import { WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
import { BiomeData, biomeExtension } from "./biomeExtension";
import { InstanceAdapter } from "./definition";
// !deadline-ts.customFinishSector_FinishModulesEnd

export class Biome {
    priority: number
    name: string
    adapter: InstanceAdapter
    constructor(adapter: InstanceAdapter) {
        this.priority = -1;
        this.name = "?";
        this.adapter = adapter;
    }
}

export function useBiomeData(yourCell: WedgeCell): BiomeData | undefined {
  const data = biomeExtension.get(yourCell);
  if (!data) return;
  return data;
}

const defaultValue = {
    whoClaimedThis: [],
    claimed: 0
};

export function structureClaimLand(thisBiome: Biome, yourCell: WedgeCell): void {
  const data = biomeExtension.get(yourCell);
  if (!data) return;
  data.claimed += 1;
  data.whoClaimedThis.push(thisBiome.name);
}

// If a cell might not have biome data yet but you want to guarantee it does by the time this function exits, getOrInit handles that without a separate has() check followed by a set()
export function ensureBiomeData(yourCell: WedgeCell): BiomeData {
  return biomeExtension.getOrInit(yourCell, () => (defaultValue));
}