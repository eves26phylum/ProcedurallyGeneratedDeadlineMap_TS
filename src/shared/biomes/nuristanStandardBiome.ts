import { AnyInstance, InstanceAdapter } from "shared/definition"
import { Biome, useBiomeData } from "shared/biome"
import humanConfig from "shared/humanConfig"
import type { createTerrain } from "shared/createTerrainFromVerticesUsingAdapter"
import { WedgeCell } from "shared/createTerrainFromVerticesUsingAdapter"
import { assign } from "shared/Util"
import { ensureBiomeData, biomeClaimLand } from "shared/biome"

export interface NuristanStandardBiomeConfig {
    desert: () => Partial<InstanceProperties<WedgePart>>
    grass: () => Partial<InstanceProperties<WedgePart>>
}
export class NuristanStandardBiome implements Biome {
    config: NuristanStandardBiomeConfig
    parent: AnyInstance
    priority: number
    name: string
    adapter: InstanceAdapter
    constructor(adapterToUse: InstanceAdapter, config: NuristanStandardBiomeConfig, parent: AnyInstance) {
        this.priority = 100;
        this.config = config;
        this.parent = parent;
        this.name = "nsb";
        this.adapter = adapterToUse;
    }
    
    private getColourAndMaterialFromHeight(height: number): Partial<InstanceProperties<WedgePart>> {
        if (height < humanConfig.grassDeepness) return this.config.grass();
        return this.config.desert();
    }
    generate(yourSelf: createTerrain, yourCell: WedgeCell) {
        if (useBiomeData(yourCell)) return;
        const operateOnThisTriangleInstance = (data: WedgeCell, triangle: AnyInstance) => {
            const height = data.data.averageHeight;
            const propMap: Partial<InstanceProperties<WedgePart>> = this.getColourAndMaterialFromHeight(height);
            assign(triangle, propMap, (a, b, c) => {this.adapter.setProperty(a, b, c);});
        }
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][0]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][1]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][0]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][1]);
        ensureBiomeData(yourCell);
        biomeClaimLand(this, yourCell);
    }
}
