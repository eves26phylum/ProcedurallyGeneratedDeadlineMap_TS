import { RoomTypeHandler, NuristanBuildings } from "shared/biomes/NuristanBuildings";
import { RoomFaceData } from "shared/ProceduralRoomGeneration";
export class LivingRoomHandler implements RoomTypeHandler {
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