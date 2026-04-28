import { EgoMoose } from "../shared/EgoMoose";
import { createTerrain, WedgeCell } from "../shared/createTerrainFromVerticesUsingAdapter";
import { robloxAdapter } from "shared/robloxAdapter";
import { deadlineAdapter } from "shared/deadlineAdapter";
import { PerlinNoise } from "shared/PerlinNoise";
import { AnyInstance, InstanceAdapter } from "shared/definition";
import { biomeBox } from "shared/biomeAndStructureRegistrySystem";
import { assign } from "shared/Util";
import { Biome } from "shared/biome";
import humanConfig from "shared/humanConfig";
import { translateTerrainOrientationForStructureBonding } from "shared/translateTerrainForStructureBonding";

// !deadline-ts.customFinishSector_FinishModulesEnd
const isDeadline = get_map_root !== undefined;
const adapterToUse: InstanceAdapter = isDeadline ? deadlineAdapter : robloxAdapter;
const workspace: AnyInstance = isDeadline ? get_map_root() : game.GetService("Workspace");

const PART_SIZE = 100;
const MAP_SIZE = new Vector2(10000, 10000);
const RESOLUTION = new Vector2(math.round(MAP_SIZE.X / PART_SIZE), math.round(MAP_SIZE.Y / PART_SIZE));
const ROUGHNESS = 4;
const PARAMS = {
    lacunarity: 4,
    persistence: 0.25,
    octaves: 2,
    exaggeratedness: 20,
    power: 3,
    scale: math.max(RESOLUTION.X, RESOLUTION.Y) / ROUGHNESS
};
const POSITION_OFFSET = new Vector3(-(MAP_SIZE.X / 2), 0, -(MAP_SIZE.Y / 2));
const offset = new Vector2(math.random(1, 10e6), math.random(1, 10e6));
const noiseData = new PerlinNoise().generate(PARAMS.scale, RESOLUTION, offset, PARAMS.exaggeratedness, PARAMS.lacunarity, PARAMS.persistence, PARAMS.octaves, PARAMS.power);
const wedgesFolderToDestroy = adapterToUse.findFirstChild(workspace, "Wedges"); // getservice because we're exporting this to deadline and there's no fucking way am I going to import an entire rbxts node module pipeline
if (wedgesFolderToDestroy) { adapterToUse.destroy(wedgesFolderToDestroy); }
const wedgesFolder = adapterToUse.newInstance("Folder");
adapterToUse.setProperty(wedgesFolder, "Name", "Wedges");
adapterToUse.setProperty(wedgesFolder, "Parent", workspace);
const standardBox = new biomeBox();

interface NuristanStandardBiomeConfig {
    desert: () => Partial<InstanceProperties<WedgePart>>
    grass: () => Partial<InstanceProperties<WedgePart>>
}
class NuristanStandardBiome extends Biome {
    config: NuristanStandardBiomeConfig
    constructor(config: NuristanStandardBiomeConfig) {
        super();
        this.priority = 100;
        this.config = config;
        this.name = "nsb";
    }
    
    private getColourAndMaterialFromHeight(height: number): Partial<InstanceProperties<WedgePart>> {
        if (height < humanConfig.grassDeepness) return this.config.grass();
        return this.config.desert();
    }
    generate(yourSelf: createTerrain, yourCell: WedgeCell) {
        const operateOnThisTriangleInstance = (data: WedgeCell, triangle: AnyInstance) => {
            const height = data.data.averageHeight;
            const propMap: Partial<InstanceProperties<WedgePart>> = this.getColourAndMaterialFromHeight(height);
            assign(triangle, propMap, (a, b, c) => {yourSelf.adapter.setProperty(a, b, c);});
        }
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][0]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][1]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][0]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][1]);
    }
}

const translateTerrain = new translateTerrainOrientationForStructureBonding({
   orientationSubtraction: new Vector3(0, 0, -90) 
});
class NuristanBuildings extends Biome {
    config: {}
    constructor(config: {}) {
        super();
        this.priority = 100;
        this.config = config;
        this.name = "NuristanBuildings";
    }
    generate(yourSelf: createTerrain, yourCell: WedgeCell) {
        const operateOnThisTriangleInstance = (data: WedgeCell, triangle: AnyInstance<WedgePart>) => {
            // const height = data.data.averageHeight;
            const translatedOrientationForStructurePlacement = translateTerrain.Translate(triangle.Orientation);
            // note: fromEulerAngles methods all use radian input. .Orientation is a degree angle. So convert.
            const degreesTiltedOfSteepness = translateTerrain.GetSteepnessInDegrees(CFrame.fromEulerAnglesXYZ(math.rad(translatedOrientationForStructurePlacement.X), math.rad(translatedOrientationForStructurePlacement.Y), math.rad(translatedOrientationForStructurePlacement.Z)));
            const isALivableDegree = degreesTiltedOfSteepness < humanConfig.maxLivableSteepness;
            if (!isALivableDegree) return;
            const part = data._self.adapter.newInstance("Part", wedgesFolder)
            part.CFrame = triangle.CFrame;
            part.Orientation = translatedOrientationForStructurePlacement;
            triangle.Name = "I'm a building!"; // for debug
            // Later: Influence from surrounding triangles to see if they have a nuristan building set on them, and not this triangle already having some sort of other structure
        }
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][0]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][1]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][0]);
        operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][1]);
    }
}
const stdnuristanconfig = {
    grass: () => {
        return {
            Material: Enum.Material.Grass, Color: Color3.fromRGB(43, 219, 84)
        }
    },
    desert: () => { 
        const secondaryAngs = math.random(-20, 10);
        return {Material: Enum.Material.Sand, Color: Color3.fromRGB(237 + secondaryAngs, 201 + math.random(0, 20), 175 + secondaryAngs)}
    }
}
standardBox.registerModifier(new NuristanStandardBiome(stdnuristanconfig))
standardBox.registerModifier(new NuristanBuildings({}));
const createTerrainDefault = new createTerrain((thisData: WedgeCell) => {
    const _self = thisData._self;
    standardBox.executeAllModifiers(thisData._self, thisData);
}, EgoMoose, adapterToUse, wedgesFolder);
const triangles = createTerrainDefault.createTrianglesFromData(noiseData, RESOLUTION, PART_SIZE, POSITION_OFFSET);