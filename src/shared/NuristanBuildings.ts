import { Biome } from "./biome";
import { AnyInstance, InstanceAdapter } from "./definition";
import { assign } from "./Util";
import humanConfig from "./humanConfig";
import { triangleVerticesTrio, WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
import { createTerrain } from "./createTerrainFromVerticesUsingAdapter";
import { translateTerrainOrientationForStructureBonding } from "./translateTerrainForStructureBonding";
import { EgoMoose } from "./EgoMoose";
import { ProceduralRoomGrid, RoomGenerationConfig, RoomFaceData, WallFace } from "./ProceduralRoomGeneration";
import { DepthFirstMazeSearch } from "./DepthFirstMazeSearch";
import { fisherYatesShuffle } from "./Util";
import { ensureStructureData, structureClaimLand, useStructureData } from "./structure";

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
- Don't add comments that point the obvious. Unless you're explaining some nuanced thing or detail, maybe an algorithm — Just don't.
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

export interface WallConfig {
    thickness: number;
    height: number;
}

export interface DoorwayDataType {
    width: number;
    height: number;
    offsetAlongWall: number;
    bottomOffset: number;
}

export interface RoomProps extends Partial<InstanceProperties<BasePart>> {
    RoomSize: Vector3;
}

export interface NuristanBuildingsConfig {
    wallPartProps: Partial<InstanceProperties<Part>>;
    doorway: DoorwayDataType;
    wall: WallConfig;
    roomProps: RoomProps;
    roomGeneration: RoomGenerationConfig;
    sniperWindowDoorway: DoorwayDataType;
}

export interface WallSegmentGeometry {
    localCFrame: CFrame;
    size: Vector3;
}

export interface RoomTypeHandler {
    priority: number;
    tryGenerate(roomCFrame: CFrame, faceData: RoomFaceData): boolean;
}

export interface FaceAxisConfig {
    faceLocalOffset: (plateSize: Vector3, thickness: number) => number;
    wallLength: (plateSize: Vector3) => number;
    buildLocalCFrame: (lengthAxisLocalPos: number, localHeightCenter: number, faceLocalOffset: number) => CFrame;
    buildSegmentSize: (segmentLength: number, segmentHeight: number, thickness: number) => Vector3;
}

export const ALL_WALL_FACES: ReadonlyArray<WallFace> = ["north", "south", "east", "west"];

const faceAxisConfigMap: Record<WallFace, FaceAxisConfig> = {
    north: {
        faceLocalOffset: (plateSize, thickness) => -(plateSize.Z / 2 - thickness / 2),
        wallLength: (plateSize) => plateSize.X,
        buildLocalCFrame: (lengthAxisLocalPos, localHeightCenter, faceLocalOffset) =>
            new CFrame(lengthAxisLocalPos, localHeightCenter, faceLocalOffset),
        buildSegmentSize: (segmentLength, segmentHeight, thickness) =>
            new Vector3(segmentLength, segmentHeight, thickness),
    },
    south: {
        faceLocalOffset: (plateSize, thickness) => plateSize.Z / 2 - thickness / 2,
        wallLength: (plateSize) => plateSize.X,
        buildLocalCFrame: (lengthAxisLocalPos, localHeightCenter, faceLocalOffset) =>
            new CFrame(lengthAxisLocalPos, localHeightCenter, faceLocalOffset),
        buildSegmentSize: (segmentLength, segmentHeight, thickness) =>
            new Vector3(segmentLength, segmentHeight, thickness),
    },
    east: {
        faceLocalOffset: (plateSize, thickness) => plateSize.X / 2 - thickness / 2,
        wallLength: (plateSize) => plateSize.Z,
        buildLocalCFrame: (lengthAxisLocalPos, localHeightCenter, faceLocalOffset) =>
            new CFrame(faceLocalOffset, localHeightCenter, lengthAxisLocalPos),
        buildSegmentSize: (segmentLength, segmentHeight, thickness) =>
            new Vector3(thickness, segmentHeight, segmentLength),
    },
    west: {
        faceLocalOffset: (plateSize, thickness) => -(plateSize.X / 2 - thickness / 2),
        wallLength: (plateSize) => plateSize.Z,
        buildLocalCFrame: (lengthAxisLocalPos, localHeightCenter, faceLocalOffset) =>
            new CFrame(faceLocalOffset, localHeightCenter, lengthAxisLocalPos),
        buildSegmentSize: (segmentLength, segmentHeight, thickness) =>
            new Vector3(thickness, segmentHeight, segmentLength),
    },
};

function computeSolidWallFaceGeometry(
    plateSize: Vector3,
    wallConfig: WallConfig,
    face: WallFace
): WallSegmentGeometry[] {
    const faceConfig = faceAxisConfigMap[face];
    const faceOffset = faceConfig.faceLocalOffset(plateSize, wallConfig.thickness);
    const wallLength = faceConfig.wallLength(plateSize);
    const localHeightCenter = wallConfig.height / 2;
    return [
        {
            localCFrame: faceConfig.buildLocalCFrame(0, localHeightCenter, faceOffset),
            size: faceConfig.buildSegmentSize(wallLength, wallConfig.height, wallConfig.thickness),
        },
    ];
}

function computeDoorwayWallFaceGeometry(
    plateSize: Vector3,
    wallConfig: WallConfig,
    doorwayData: DoorwayDataType,
    face: WallFace
): WallSegmentGeometry[] {
    const faceConfig = faceAxisConfigMap[face];
    const faceOffset = faceConfig.faceLocalOffset(plateSize, wallConfig.thickness);
    const wallLength = faceConfig.wallLength(plateSize);
    const sillHeight = doorwayData.bottomOffset;

    const leftSegmentWidth = (wallLength - doorwayData.width) / 2 + doorwayData.offsetAlongWall;
    const rightSegmentWidth = (wallLength - doorwayData.width) / 2 - doorwayData.offsetAlongWall;
    const headerHeight = wallConfig.height - doorwayData.height - sillHeight;
    const leftSegmentLengthCenter = -(wallLength / 2) + leftSegmentWidth / 2;
    const rightSegmentLengthCenter = wallLength / 2 - rightSegmentWidth / 2;

    const segments: WallSegmentGeometry[] = [
        {
            localCFrame: faceConfig.buildLocalCFrame(leftSegmentLengthCenter, wallConfig.height / 2, faceOffset),
            size: faceConfig.buildSegmentSize(leftSegmentWidth, wallConfig.height, wallConfig.thickness),
        },
        {
            localCFrame: faceConfig.buildLocalCFrame(rightSegmentLengthCenter, wallConfig.height / 2, faceOffset),
            size: faceConfig.buildSegmentSize(rightSegmentWidth, wallConfig.height, wallConfig.thickness),
        },
    ];

    if (headerHeight > 0) {
        const headerLocalHeightCenter = sillHeight + doorwayData.height + headerHeight / 2;
        segments.push({
            localCFrame: faceConfig.buildLocalCFrame(doorwayData.offsetAlongWall, headerLocalHeightCenter, faceOffset),
            size: faceConfig.buildSegmentSize(doorwayData.width, headerHeight, wallConfig.thickness),
        });
    }

    if (sillHeight > 0) {
        segments.push({
            localCFrame: faceConfig.buildLocalCFrame(doorwayData.offsetAlongWall, sillHeight / 2, faceOffset),
            size: faceConfig.buildSegmentSize(doorwayData.width, sillHeight, wallConfig.thickness),
        });
    }

    return segments;
}

function instantiateWallSegments(
    plateCFrame: CFrame,
    segments: WallSegmentGeometry[],
    partProps: Partial<InstanceProperties<Part>>,
    parent: AnyInstance,
    adapter: InstanceAdapter
): void {
    for (const segment of segments) {
        const worldCFrame = plateCFrame.mul(segment.localCFrame);
        const wallPart = adapter.newInstance("Part");
        adapter.setProperty(wallPart, "CFrame", worldCFrame);
        adapter.setProperty(wallPart, "Size", segment.size);
        adapter.setProperty(wallPart, "Anchored", true);
        assign(wallPart, partProps, adapter.setProperty);
        adapter.setProperty(wallPart, "Parent", parent);
    }
}

export class NuristanBuildings implements Biome {
    config: NuristanBuildingsConfig;
    parent: AnyInstance;
    translateTerrain: translateTerrainOrientationForStructureBonding;
    roomHandlers: RoomTypeHandler[]
    priority: number
    name: string
    adapter: InstanceAdapter
    constructor(adapterToUse: InstanceAdapter, translateTerrain: translateTerrainOrientationForStructureBonding, config: NuristanBuildingsConfig, parent: AnyInstance, roomHandlers: (thisThing: NuristanBuildings) => RoomTypeHandler[]) {
        this.priority = 50; // priority of structures should be less than priority of biomes
        this.config = config;
        this.translateTerrain = translateTerrain;
        this.parent = parent;
        this.name = "NuristanBuildings";
        this.roomHandlers = roomHandlers(this);
        this.adapter = adapterToUse;
    }

    private mergeConfig(overrides: Partial<NuristanBuildingsConfig>): NuristanBuildingsConfig {
        const merged = { ...this.config };
        assign(merged, overrides);
        return merged;
    }

    makeWallWithoutDoorway(
        roomPlateCFrame: CFrame,
        roomPlateSize: Vector3,
        face: WallFace,
        configOverrides?: Partial<NuristanBuildingsConfig>
    ): void {
        const resolvedConfig = configOverrides !== undefined ? this.mergeConfig(configOverrides) : this.config;
        const segments = computeSolidWallFaceGeometry(roomPlateSize, resolvedConfig.wall, face);
        instantiateWallSegments(roomPlateCFrame, segments, resolvedConfig.wallPartProps, this.parent, this.adapter);
    }

    makeWallWithDoorway(
        roomPlateCFrame: CFrame,
        roomPlateSize: Vector3,
        face: WallFace,
        configOverrides?: Partial<NuristanBuildingsConfig>
    ): void {
        const resolvedConfig = configOverrides !== undefined ? this.mergeConfig(configOverrides) : this.config;
        const segments = computeDoorwayWallFaceGeometry(roomPlateSize, resolvedConfig.wall, resolvedConfig.doorway, face);
        instantiateWallSegments(roomPlateCFrame, segments, resolvedConfig.wallPartProps, this.parent, this.adapter);
    }

    instantiateRoomShell(roomCFrame: CFrame, configOverrides?: Partial<NuristanBuildingsConfig>): void {
        const resolvedConfig = configOverrides !== undefined ? this.mergeConfig(configOverrides) : this.config;
        const roomSize = resolvedConfig.roomProps.RoomSize;

        const roomPlate = this.adapter.newInstance("Part");
        this.adapter.setProperty(roomPlate, "CFrame", roomCFrame);
        this.adapter.setProperty(roomPlate, "Size", roomSize);
        this.adapter.setProperty(roomPlate, "Anchored", true);
        assign(roomPlate, resolvedConfig.wallPartProps, this.adapter.setProperty);
        this.adapter.setProperty(roomPlate, "Parent", this.parent);

        const roomRoof = this.adapter.newInstance("Part");
        this.adapter.setProperty(roomRoof, "CFrame", roomCFrame.add(roomCFrame.UpVector.mul(resolvedConfig.wall.height).add(roomCFrame.UpVector.mul(roomSize.Y / 2))));
        this.adapter.setProperty(roomRoof, "Size", roomSize);
        this.adapter.setProperty(roomRoof, "Name", "RoomRoof");
        this.adapter.setProperty(roomRoof, "Anchored", true);
        assign(roomRoof, resolvedConfig.wallPartProps, this.adapter.setProperty);
        this.adapter.setProperty(roomRoof, "Parent", this.parent);
    }

    createStandardRoom(roomCFrame: CFrame, faceData: RoomFaceData, configOverrides?: Partial<NuristanBuildingsConfig>): void {
        this.instantiateRoomShell(roomCFrame, configOverrides);
        const resolvedConfig = configOverrides !== undefined ? this.mergeConfig(configOverrides) : this.config;
        const roomSize = resolvedConfig.roomProps.RoomSize;
        for (const face of ALL_WALL_FACES) {
            const faceDatum = faceData[face];
            if (faceDatum.state === "empty") continue;
            if (faceDatum.state === "doorway") {
                this.makeWallWithDoorway(roomCFrame, roomSize, face, configOverrides);
                continue;
            }
            this.makeWallWithoutDoorway(roomCFrame, roomSize, face, configOverrides);
        }
    }

    createSingleHouse(houseCFrame: CFrame, vertices: [Vector3, Vector3, Vector3]): void {
        const registeredRoomTypeNames: ReadonlyArray<string> = ["LivingRoom"];
        const proceduralGrid = new ProceduralRoomGrid(
            this.config.roomGeneration,
            registeredRoomTypeNames,
            new DepthFirstMazeSearch(fisherYatesShuffle),
            fisherYatesShuffle
        );

        const entranceHeightResult = EgoMoose.getBarycentricHeight(
            vertices[0], vertices[1], vertices[2],
            new Vector2(houseCFrame.X, houseCFrame.Z)
        );
        if (entranceHeightResult[0] === undefined) return;

        const baseCFrame = houseCFrame.Rotation.add(new Vector3(houseCFrame.Position.X, 0, houseCFrame.Position.Z));
        const entranceCFrame = baseCFrame.add(new Vector3(0, entranceHeightResult[0], 0));
        const roomSize = this.config.roomProps.RoomSize;

        proceduralGrid.forEachRoom((gridColumn, gridRow, faceData) => {
            const roomCFrame = entranceCFrame.mul(new CFrame(roomSize.X * gridColumn, 0, roomSize.Z * gridRow));
            for (const handler of this.roomHandlers) {
                if (handler.tryGenerate(roomCFrame, faceData)) break;
            }
        });
    }

                    // triangles: [
                    //     this.materialiseTriangle(topLeft, topRight, bottomLeft),
                    //     this.materialiseTriangle(topRight, bottomRight, bottomLeft),
                    // ],
                    // data: {
                    //     vertices: [topLeft, topRight, bottomLeft, bottomRight],
                    //     averageHeight: getFromXY(x, y) / maxSize,
                    //     averageHeightSized: getFromXY(x, y),
                    //     x: x,
                    //     y: y
                    // },
    private operateOnThisTriangleInstance(data: WedgeCell, trianglePair: [AnyInstance<WedgePart>, AnyInstance<WedgePart>], verticesForTriangles: triangleVerticesTrio): void {
        const orientation = trianglePair[0].Orientation;
        const middlePos = trianglePair[0].CFrame.Lerp(trianglePair[1].CFrame, 0.5);
        const translatedOrientationForStructurePlacement = this.translateTerrain.Translate(orientation);
        const degreesTiltedOfSteepness = this.translateTerrain.GetSteepnessInDegrees(
            CFrame.fromEulerAnglesXYZ(
                math.rad(translatedOrientationForStructurePlacement.X),
                math.rad(translatedOrientationForStructurePlacement.Y),
                math.rad(translatedOrientationForStructurePlacement.Z)
            )
        );
        const isALivableDegree = degreesTiltedOfSteepness < humanConfig.maxLivableSteepness;
        if (!isALivableDegree) return;
        // const part = this.adapter.newInstance("Part");
        // this.adapter.setProperty(part, "CFrame", middlePos);
        // this.adapter.setProperty(part, "Orientation", translatedOrientationForStructurePlacement);
        // this.adapter.setProperty(part, "Parent", this.parent);
        const rotationalCFrame = CFrame.fromEulerAnglesXYZ(math.rad(translatedOrientationForStructurePlacement.X), math.rad(translatedOrientationForStructurePlacement.Y + math.random(0, 360)), math.rad(translatedOrientationForStructurePlacement.Z));
        this.createSingleHouse(rotationalCFrame.add(middlePos.Position), verticesForTriangles);
    }

    generate(yourSelf: createTerrain, yourCell: WedgeCell): void {
        if (useStructureData(yourCell)) return;
        this.operateOnThisTriangleInstance(yourCell, yourCell.triangles[0], yourCell.verticesForTriangles[0]);
        this.operateOnThisTriangleInstance(yourCell, yourCell.triangles[1], yourCell.verticesForTriangles[1]);
        ensureStructureData(yourCell);
        structureClaimLand(this, yourCell);
    }
}