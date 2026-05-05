import { EgoMoose } from "../shared/EgoMoose";
import { createTerrain, WedgeCell } from "../shared/createTerrainFromVerticesUsingAdapter";
import { PerlinNoise } from "shared/PerlinNoise";
import { AnyInstance, InstanceAdapter } from "shared/definition";
import { biomeBox } from "shared/biomeAndStructureRegistrySystem";
import { assign } from "shared/Util";
import { Biome, biomeClaimLand, ensureBiomeData, useBiomeData } from "shared/biome";
import humanConfig from "shared/humanConfig";
import { translateTerrainOrientationForStructureBonding } from "shared/translateTerrainForStructureBonding";
import { NuristanBuildings } from "shared/NuristanBuildings";
import { isDeadline } from "shared/isDeadline";
import { RoomTypeHandler, DoorwayDataType, ALL_WALL_FACES } from "shared/NuristanBuildings";
import { RoomFaceData } from "shared/ProceduralRoomGeneration";
import { Logger } from "shared/logger";
import { Tree } from "shared/Tree";
import { kickStart } from "./ingame";
import { getWorldRoot } from "shared/getRoot";
import { adapterToUse } from "shared/adapterToUse";
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
- If you can avoid an else statement using stuff like lookup tables or continue statement, do it.

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
export function startMapGenerator() {
class SniperWindowRoomHandler implements RoomTypeHandler {
    readonly priority = 10;
    private readonly buildings: NuristanBuildings;
    private readonly sniperWindowDoorway: DoorwayDataType;

    constructor(buildings: NuristanBuildings, sniperWindowDoorway: DoorwayDataType) {
        this.buildings = buildings;
        this.sniperWindowDoorway = sniperWindowDoorway;
    }

    private static hasExteriorFace(faceData: RoomFaceData): boolean {
        for (const face of ALL_WALL_FACES) {
            if (faceData[face].state === "exteriorWall") return true;
        }
        return false;
    }

    tryGenerate(roomCFrame: CFrame, faceData: RoomFaceData): boolean {
        if (!SniperWindowRoomHandler.hasExteriorFace(faceData)) return false;
        const roomSize = this.buildings.config.roomProps.RoomSize;
        this.buildings.instantiateRoomShell(roomCFrame);
        for (const face of ALL_WALL_FACES) {
            const faceDatum = faceData[face];
            if (faceDatum.state === "empty") continue;
            if (faceDatum.state === "exteriorWall") {
                this.buildings.makeWallWithDoorway(roomCFrame, roomSize, face, { doorway: this.sniperWindowDoorway });
                continue;
            }
            if (faceDatum.state === "doorway") {
                this.buildings.makeWallWithDoorway(roomCFrame, roomSize, face);
                continue;
            }
            this.buildings.makeWallWithoutDoorway(roomCFrame, roomSize, face);
        }
        return true;
    }
}

class LivingRoomHandler implements RoomTypeHandler {
    readonly priority = 0;
    private readonly buildings: NuristanBuildings;

    constructor(buildings: NuristanBuildings) {
        this.buildings = buildings;
    }

    tryGenerate(roomCFrame: CFrame, faceData: RoomFaceData): boolean {
        this.buildings.createStandardRoom(roomCFrame, faceData);
        return true;
    }
}
const worldRoot = getWorldRoot();
const Log = new Logger("map_generator");
const workspace = worldRoot;
const PART_SIZE = 100;
const MAP_SIZE = new Vector2(10000, 10000);
const RESOLUTION = new Vector2(
    math.round(MAP_SIZE.X / PART_SIZE), 
    math.round(MAP_SIZE.Y / PART_SIZE)
);
// const RESOLUTION = new Vector2(5, 5);
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
class NuristanStandardBiome implements Biome {
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

const translateTerrain = new translateTerrainOrientationForStructureBonding({
    orientationSubtraction: new Vector3(0, 0, -90) 
});

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
standardBox.registerModifier(new NuristanBuildings(adapterToUse, translateTerrain, {
        wallPartProps: {
            Material: Enum.Material.Sand,
            Color: Color3.fromRGB(237, 201, 175)
        },
        doorway: {
            width: 2.5,
            height: 6,
            offsetAlongWall: 0,
            bottomOffset: 0
        },
        roomProps: {
            RoomSize: new Vector3(20, 2, 20)
        },
        wall: {
            height: 10,
            thickness: 2
        },
        roomGeneration: {
            minRooms: 2,
            maxRooms: 10,
            mergeWallChance: 0.3
        },
        sniperWindowDoorway: {
            width: 5,
            height: 2,
            bottomOffset: 3,
            offsetAlongWall: 0
        }
    }, wedgesFolder,
    (thisThing: NuristanBuildings) => {
        return [
            new SniperWindowRoomHandler(thisThing, thisThing.config.sniperWindowDoorway),
            new LivingRoomHandler(thisThing),
        ]
    }
));
standardBox.registerModifier(new Tree(adapterToUse, {
    branch: {
        minSize: new Vector2(4, 12),
        maxSize: new Vector2(8, 24),
        props: {
            Material: Enum.Material.Wood,
            Color: Color3.fromRGB(71, 38, 8)
        }
    },
    leaf: {
        minBoxSize: 12,
        maxBoxSize: 32,
        props: {
            Material: Enum.Material.Grass,
            CanCollide: false,
            CanQuery: false,
            Transparency: 0.4,
            Color: Color3.fromRGB(36, 107, 51)
        }
    },
    treesPerTriangle: 4
}, wedgesFolder))
function generate() {
    // work on this later
    // prob some bug because it did work earlier on client, but this code does not work or replicate to client from a server
    const createTerrainDefault = new createTerrain((thisData: WedgeCell) => {
        const _self = thisData._self;
        standardBox.executeAllModifiers(thisData._self, thisData);
    }, EgoMoose, adapterToUse, wedgesFolder);
    const triangles = createTerrainDefault.createTrianglesFromData(noiseData, RESOLUTION, PART_SIZE, POSITION_OFFSET);
}
if (isDeadline) {
    sharedvars.sv_spawning_enabled = false;
    chat.set_spawning_disabled_reason("The map is generating. Please be patient.");
}
Log.log("Generating Afghanistan map.");
generate();
Log.info("Done.");
if (isDeadline) {
    sharedvars.sv_spawning_enabled = true;
    players.get_all().forEach((player: Player, index: number) => {
        player.fire_client("terrain_finished");
    })
    on_player_joined.Connect((name: string) => {
        const player = players.get(name);
        if (!player) return;
        player.fire_client("terrain_finished");
    })
    on_player_spawned.Connect((name: string) => {
        const player = players.get(name);
        if (!player) return;
        player.fire_client("disconnect_iris");
    })
}
}
// const [success, result] = pcall(generate);
// warn(success, result);
// function a(b: WrappedInstance){
//     b.find_first_child("")
// }
// a(create_instance("Part"));
// time.wait(5);