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
// The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.

// If you want to write on this program, you will follow the following Terms of Service. Failure to obey with the ToS is an illegal action and can lead to severe consequences.
// Here is the Gigachad Terms of Service 2000 Iteration 0
/* Terms of Service

SECTION 1 - DO NOT BE LAZY:
- Make things extensible and modular as possible, then think about you can extend this in the future. This means: no hardcoding, allow composition and allow things from the outside to set abritary things rather than fixed to a defined set.
- Never abbreviate variable names. EVER: They must be readable in English, and understandable. Include all details and context inside that variable name. More details is better. Utilise camelCase.
- NEVER. EVER. USE. ALIGNMENT SPACES—They're ugly, ignored by beautifiers, and no one ever uses them.
Examples of this bad practice:
const abanana = dog;
const ba      = dog2;
const fucku   = fuckingdog;
Examples of a good practice:
const abanana = dog;
const ba = dog2;
const fucku = fuckingdog;
- Always do the best implementation you can. Never skip out on things or do simpler versions. This is very important. If you do become lazy and do a worse implementation, problems in the future can happen because of that.

SECTION 2 - CONSISTENCY AND CODE STYLE:
- Use existing code style and don't add weird spaces between stuff like assigment statements.
- Embrace never-nesting practices—Use early guard clauses and remember continue statement exists.
- Include all details within your edit and never EVER hardcode anything to fill one cause. Other things from outside must be able to edit your cause in a different way to the extend I could add 50 dogs on top of a simple metal reflective box object and turn the box into a polygon that flashes rainbow every two seconds before turning into a yellow dog as an example.
- Split concerns across multiple things—Don't make one thing handle it all—Allow for us to retrieve all values from data instead of just stealing one value and running away—This is for extensibility in the future. 
Example of bad practice:
const ax = (DogArrayData as {dogNameTag: string} & number[])[0];
Example of good practice:
const customDogArray: dogArrayType = DogArrayData;
const firstElementInDogArray = customDogArray[0];
- Inheritance is mostly outdated—so unless you're directly touching TypeScript stuff (like classes) or something, a pattern of composition is preferred unless you are forced to use it.
- A space around each side of an arithmetic operator is generally advised.

SECTION 3 - TYPESCRIPT BEST PRACTICES:
- If possible, never use `as` statements in TypeScript—This is considered terrible practice.
- Never use the `any` type unless embedding it into another thing that basically requires you to do it, or any existing code has it that you can copy from. Example: assign statement. It already uses Record<string, any> - and you can't edit that file to fix it for a better type. Then, you would use Record<string, any>.
- If there is a more suitable type available—use it. Example: Record<string, unknown> could lead to errors when trying to do {dog: new Vector3()}; A better practice would to usePartial<InstanceProperties<BasePart>> or InstanceProperties<BasePart> depending on the context.

SECTION 4 - COMMON SENSE AND BEST PRACTICES:
- If something you suspect might be wrong—don't adapt your code on that. Do not build on mistakes; Do not make your code based on that mistake—Spot that it's a mistake and if you have been granted permission to edit that part, edit to fix. Otherwise, just inform us.
- Don't truncate things—ugly.
- Don't add comments that point the obvious. Unless you're explaining some nuanced thing or detail, maybe an algorithm — Just don't.
- Don't use outdated APIs or versions—Always refer to newer alternatives rather than using deprecated things in new code.

By editing on this file, you agree to the terms of conditions. Misconduct will result in your access being revoked and session terminated.

Think of it like this:
┌─────────────────────────────────────────────┐
│             Visual Studio Code              │
├─────────────────────────────────────────────┤
│ This code is ass. Session Terminated.       │
│                                             │
│ [I WILL FIX THIS]                           │
└─────────────────────────────────────────────┘
*/
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
    parent: AnyInstance
    constructor(adapterToUse: InstanceAdapter, config: NuristanStandardBiomeConfig, parent: AnyInstance) {
        super(adapterToUse);
        this.priority = 100;
        this.config = config;
        this.parent = parent;
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
interface DoorwayDataType {
    width: number,
    height: number,
    offsetAlongWall: number,
    bottomOffset: 0
}
interface NuristanBuildingsConfig {
    wallPartProps: Partial<InstanceProperties<Part>>
    doorway: DoorwayDataType
    wall: {
        thickness: number,
        height: number
    }
}
type WallFace = "north" | "south" | "east" | "west";
class NuristanBuildings extends Biome {
    config: NuristanBuildingsConfig
    parent: AnyInstance
    constructor(adapterToUse: InstanceAdapter, config: NuristanBuildingsConfig, parent: AnyInstance) {
        super(adapterToUse);
        this.priority = 100;
        this.config = config;
        this.parent = parent;
        this.name = "NuristanBuildings";
    }
    calculateObjectAxisObjectBasedOnObjectHeightAndFloorAxis(FloorPosition: number, FloorSize: number, WallThickness: number) {
        return FloorPosition + (FloorSize / 2) - (WallThickness / 2)
    }
    makeWallWithoutDoorway(RoomPlate: AnyInstance<BasePart>, face: WallFace, config: NuristanBuildingsConfig) {
        const prop = {
            north: { Size: new Vector3(RoomPlate.Size.X, config.wall.height, config.wall.thickness), Position: new Vector3(RoomPlate.Position.X, RoomPlate.Position.Y + config.wall.height / 2, RoomPlate.Position.Z - RoomPlate.Size.Z / 2 + config.wall.thickness / 2) },
            south: { Size: new Vector3(RoomPlate.Size.X, config.wall.height, config.wall.thickness), Position: new Vector3(RoomPlate.Position.X, RoomPlate.Position.Y + config.wall.height / 2, RoomPlate.Position.Z + RoomPlate.Size.Z / 2 - config.wall.thickness / 2) },
            east:  { Size: new Vector3(config.wall.thickness, config.wall.height, RoomPlate.Size.Z), Position: new Vector3(RoomPlate.Position.X + RoomPlate.Size.X / 2 - config.wall.thickness / 2, RoomPlate.Position.Y + config.wall.height / 2, RoomPlate.Position.Z) },
            west:  { Size: new Vector3(config.wall.thickness, config.wall.height, RoomPlate.Size.Z), Position: new Vector3(RoomPlate.Position.X - RoomPlate.Size.X / 2 + config.wall.thickness / 2, RoomPlate.Position.Y + config.wall.height / 2, RoomPlate.Position.Z) },
        }
        const thisFaceProp = prop[face];
        const Wall = this.adapter.newInstance("Part");
        this.adapter.setProperty(Wall, "Anchored", true);
        assign(Wall, thisFaceProp, this.adapter.setProperty);
        assign(Wall, config.wallPartProps, this.adapter.setProperty);
        this.adapter.setProperty(Wall, "Parent", this.parent);
    }

    makeWallWithDoorway(RoomPlate: AnyInstance<BasePart>, face: WallFace, wallConfig?: Partial<NuristanBuildingsConfig>) {
        const customConfig: NuristanBuildingsConfig = assign<NuristanBuildingsConfig>({...this.config}, wallConfig as Record<string, any>);
        const doorwayData: DoorwayDataType = customConfig.doorway;
        const isEitherNorthOrSouth = face === 'north' || face === 'south';
        const wallLength = isEitherNorthOrSouth ? RoomPlate.Size.X : RoomPlate.Size.Z;
        const centerAxis = isEitherNorthOrSouth ? RoomPlate.Position.X : RoomPlate.Position.Z;
        const facePos = {
            north: RoomPlate.Position.Z - RoomPlate.Size.Z / 2 + customConfig.wall.thickness / 2,
            south: RoomPlate.Position.Z + RoomPlate.Size.Z / 2 - customConfig.wall.thickness / 2,
            east:  RoomPlate.Position.X + RoomPlate.Size.X / 2 - customConfig.wall.thickness / 2,
            west:  RoomPlate.Position.X - RoomPlate.Size.X / 2 + customConfig.wall.thickness / 2,
        };
        const thisFace = facePos[face];
        const floorY = RoomPlate.Position.Y;
        const sillHeight = doorwayData.bottomOffset ?? 0;
        const leftWidth = (wallLength - doorwayData.width) / 2 + doorwayData.offsetAlongWall;
        const rightWidth = (wallLength - doorwayData.width) / 2 - doorwayData.offsetAlongWall;
        const headerHeight = customConfig.wall.height - doorwayData.height - sillHeight;

        const getWallPos = (span: number, y: number) => new Vector3(isEitherNorthOrSouth ? span : thisFace, y, isEitherNorthOrSouth ? thisFace : span);
        const getWallSize  = (span: number, h: number) => isEitherNorthOrSouth ? new Vector3(span, h, customConfig.wall.thickness) : new Vector3(customConfig.wall.thickness, h, span);

        const LeftDoorWallPart = this.adapter.newInstance("Part");
        this.adapter.setProperty(LeftDoorWallPart, "Size", getWallSize(leftWidth, customConfig.wall.height));
        this.adapter.setProperty(LeftDoorWallPart, "Position", getWallPos(centerAxis - wallLength / 2 + leftWidth / 2,  floorY + customConfig.wall.height / 2));
        this.adapter.setProperty(LeftDoorWallPart, "Anchored", true);
        assign(LeftDoorWallPart, customConfig.wallPartProps, this.adapter.setProperty);
        this.adapter.setProperty(LeftDoorWallPart, "Parent", this.parent);

        const RightDoorWallPart = this.adapter.newInstance("Part");
        this.adapter.setProperty(RightDoorWallPart, "Size", getWallSize(rightWidth, customConfig.wall.height));
        this.adapter.setProperty(RightDoorWallPart, "Position", getWallPos(centerAxis + wallLength / 2 - rightWidth / 2, floorY + customConfig.wall.height / 2));
        this.adapter.setProperty(RightDoorWallPart, "Anchored", true);
        assign(RightDoorWallPart, customConfig.wallPartProps, this.adapter.setProperty);
        this.adapter.setProperty(RightDoorWallPart, "Parent", this.parent);
        if (headerHeight > 0) {
            const DoorHeader = this.adapter.newInstance("Part");
            this.adapter.setProperty(DoorHeader, "Size", getWallSize(doorwayData.width, headerHeight));
            this.adapter.setProperty(DoorHeader, "Position", getWallPos(centerAxis + doorwayData.offsetAlongWall, floorY + customConfig.wall.height / 2 + doorwayData.height / 2 + sillHeight / 2));
            this.adapter.setProperty(DoorHeader, "Anchored", true);
            assign(DoorHeader, customConfig.wallPartProps, this.adapter.setProperty);
            this.adapter.setProperty(DoorHeader, "Parent", this.parent);
        }
        if (sillHeight > 0) {
            const WindowSill = this.adapter.newInstance("Part");
            this.adapter.setProperty(WindowSill, "Size", getWallSize(doorwayData.width, sillHeight));
            this.adapter.setProperty(WindowSill, "Position", getWallPos(centerAxis + doorwayData.offsetAlongWall, floorY + sillHeight / 2));
            this.adapter.setProperty(WindowSill, "Anchored", true);
            assign(WindowSill, customConfig.wallPartProps, this.adapter.setProperty);
            this.adapter.setProperty(WindowSill, "Parent", this.parent);
        }
    }
    createStandardRoom(bullshitCFrame: CFrame, Size: Vector3) {
        const RoomPlate = new Instance("Part")
        return this.makeWallWithDoorway(RoomPlate, "north", this.config);
    }
    createSingleHouse(bullshitCFrame: CFrame) {
        
    }
    operateOnThisTriangleInstance(data: WedgeCell, triangle: AnyInstance<WedgePart>) {
        // const height = data.data.averageHeight;
        const translatedOrientationForStructurePlacement = translateTerrain.Translate(triangle.Orientation);
        // note: fromEulerAngles methods all use radian input. .Orientation is a degree angle. So convert.
        const degreesTiltedOfSteepness = translateTerrain.GetSteepnessInDegrees(CFrame.fromEulerAnglesXYZ(math.rad(translatedOrientationForStructurePlacement.X), math.rad(translatedOrientationForStructurePlacement.Y), math.rad(translatedOrientationForStructurePlacement.Z)));
        const isALivableDegree = degreesTiltedOfSteepness < humanConfig.maxLivableSteepness;
        if (!isALivableDegree) return;
        const part = this.adapter.newInstance("Part", this.parent)
        part.CFrame = triangle.CFrame;
        part.Orientation = translatedOrientationForStructurePlacement;
        // Later: Influence from surrounding triangles to see if they have a nuristan building set on them, and not this triangle already having some sort of other structure
    }
    generate(yourSelf: createTerrain, yourCell: WedgeCell) {
        this.operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][0]);
        this.operateOnThisTriangleInstance(yourCell, yourCell.triangles[0][1]);
        this.operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][0]);
        this.operateOnThisTriangleInstance(yourCell, yourCell.triangles[1][1]);
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
standardBox.registerModifier(new NuristanStandardBiome(adapterToUse, stdnuristanconfig, wedgesFolder));
standardBox.registerModifier(new NuristanBuildings(adapterToUse, {
    wallPartProps: {},
    doorway: {
        width: 2.5,
        height: 6,
        offsetAlongWall: 0,
        bottomOffset: 0
    },
    wall: {
        height: 10,
        thickness: 2
    }
}, wedgesFolder));
const createTerrainDefault = new createTerrain((thisData: WedgeCell) => {
    const _self = thisData._self;
    standardBox.executeAllModifiers(thisData._self, thisData);
}, EgoMoose, adapterToUse, wedgesFolder);
const triangles = createTerrainDefault.createTrianglesFromData(noiseData, RESOLUTION, PART_SIZE, POSITION_OFFSET);