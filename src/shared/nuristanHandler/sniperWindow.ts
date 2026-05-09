import { RoomTypeHandler } from "shared/biomes/NuristanBuildings";
import { NuristanBuildings } from "shared/biomes/NuristanBuildings";
import { DoorwayDataType } from "shared/biomes/NuristanBuildings";
import { RoomFaceData } from "shared/ProceduralRoomGeneration";
import { ALL_WALL_FACES } from "shared/biomes/NuristanBuildings";
// !deadline-ts.customFinishSector_FinishModulesEnd
export class SniperWindowRoomHandler implements RoomTypeHandler {
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