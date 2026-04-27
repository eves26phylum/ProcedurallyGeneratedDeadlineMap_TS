import { EgoMoose } from "../shared/EgoMoose";
import { createTerrain, WedgeCell } from "../shared/createTerrainFromVerticesUsingAdapter";
import { robloxAdapter } from "shared/robloxAdapter";
import { deadlineAdapter } from "shared/deadlineAdapter";
import { PerlinNoise } from "shared/PerlinNoise";
import { AnyInstance, InstanceAdapter } from "shared/definition";

// !deadline-ts.customFinishSector_FinishModulesEnd
const isDeadline = game !== undefined;
const adapterToUse: InstanceAdapter = isDeadline ? robloxAdapter : deadlineAdapter;
const workspace: AnyInstance = isDeadline ? game.GetService("Workspace") : get_map_root();

const PART_SIZE = 100;
const RESOLUTION = new Vector2(math.round(10000 / PART_SIZE), math.round(10000 / PART_SIZE));
const ROUGHNESS = 4;
const PARAMS = {
    lacunarity: 4,
    persistence: 0.25,
    octaves: 2,
    exaggeratedness: 20,
    power: 3,
    scale: math.max(RESOLUTION.X, RESOLUTION.Y) / ROUGHNESS
};
const POSITION_OFFSET = new Vector3(0, 0, 0);
const offset = new Vector2(math.random(1, 10e6), math.random(1, 10e6));
const noiseData = new PerlinNoise().generate(PARAMS.scale, RESOLUTION, offset, PARAMS.exaggeratedness, PARAMS.lacunarity, PARAMS.persistence, PARAMS.octaves, PARAMS.power);
const wedgesFolderToDestroy = adapterToUse.findFirstChild(workspace, "Wedges"); // getservice because we're exporting this to deadline and there's no fucking way am I going to import an entire rbxts node module pipeline
if (wedgesFolderToDestroy) { adapterToUse.destroy(wedgesFolderToDestroy); }
const wedgesFolder = adapterToUse.newInstance("Folder");
adapterToUse.setProperty(wedgesFolder, "Name", "Wedges");
adapterToUse.setProperty(wedgesFolder, "Parent", workspace);
function getColourAndMaterialFromHeight(height: number) {
    if (height < 0.1) return [Enum.Material.Grass]
}
function operateOnThisTriangleInstance(data: WedgeCell, triangle: AnyInstance) {
    const height = data.data.averageHeight;
    const [material, colour] = [Enum.Material.Sand, ColorSequence.fromRGB()];
}
const createTerrainDefault = new createTerrain(function(thisData: WedgeCell) {
    operateOnThisTriangleInstance(thisData, thisData.triangles[0][0]);
    operateOnThisTriangleInstance(thisData, thisData.triangles[0][1]);
    operateOnThisTriangleInstance(thisData, thisData.triangles[1][0]);
    operateOnThisTriangleInstance(thisData, thisData.triangles[1][1]);
}, EgoMoose, adapterToUse);
const triangles = createTerrainDefault.createTrianglesFromData(noiseData, RESOLUTION, PART_SIZE, POSITION_OFFSET);