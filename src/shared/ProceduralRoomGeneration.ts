import { MazeGenerationStrategy, mazePassageKey } from "./DepthFirstMazeSearch";
import { ShuffleFunction } from "./Util";

// !deadline-ts.customFinishSector_FinishModulesEnd
// The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.

export interface RoomGenerationConfig {
    minRooms: number;
    maxRooms: number;
    mergeWallChance: number;
}

export type WallFace = "north" | "south" | "east" | "west";
export type WallFaceState = "doorway" | "empty" | "interiorWall" | "exteriorWall";

export interface WallFaceData {
    state: WallFaceState;
}

export type RoomFaceData = Record<WallFace, WallFaceData>;

const EXIT_ROOM_CELL_TYPE = "__exitRoom__";

type RoomGridCell = string;
type RoomGridRow = RoomGridCell[];
type RoomGrid = RoomGridRow[];

export class ProceduralRoomGrid {
    private readonly roomGrid: RoomGrid;
    private readonly roomFaceDataMap: Map<string, RoomFaceData>;
    private readonly shuffleFunction: ShuffleFunction;

    constructor(
        generationConfig: RoomGenerationConfig,
        registeredRoomTypeNames: ReadonlyArray<string>,
        mazeStrategy: MazeGenerationStrategy,
        shuffleFunction: ShuffleFunction
    ) {
        this.shuffleFunction = shuffleFunction;
        this.roomGrid = this.buildRoomGrid(generationConfig, registeredRoomTypeNames);
        const passages = mazeStrategy.generatePassages((gridColumn, gridRow) => this.hasRoom(gridColumn, gridRow), 0, 0);
        const mergedWalls = this.generateMergedWalls(passages, generationConfig.mergeWallChance);
        this.roomFaceDataMap = this.computeAllRoomFaceData(passages, mergedWalls);
    }

    static hasRoomInGrid(roomGrid: RoomGrid, gridColumn: number, gridRow: number): boolean {
        return !!roomGrid[gridColumn]?.[gridRow];
    }

    hasRoom(gridColumn: number, gridRow: number): boolean {
        return ProceduralRoomGrid.hasRoomInGrid(this.roomGrid, gridColumn, gridRow);
    }

    forEachRoom(callback: (gridColumn: number, gridRow: number, faceData: RoomFaceData, roomType: string) => void): void {
        for (let gridColumn = 0; gridColumn < this.roomGrid.size(); gridColumn++) {
            const roomRow = this.roomGrid[gridColumn];
            if (!roomRow) continue;
            for (let gridRow = 0; gridRow < roomRow.size(); gridRow++) {
                if (!this.hasRoom(gridColumn, gridRow)) continue;
                const faceData = this.roomFaceDataMap.get(`${gridColumn},${gridRow}`);
                if (!faceData) continue;
                callback(gridColumn, gridRow, faceData, this.roomGrid[gridColumn][gridRow]);
            }
        }
    }
    private buildRoomGrid(generationConfig: RoomGenerationConfig, registeredRoomTypeNames: ReadonlyArray<string>): RoomGrid {
        const roomGrid: RoomGrid = [];
        const targetRoomCount = generationConfig.minRooms + math.floor(
            math.random() * (generationConfig.maxRooms - generationConfig.minRooms + 1)
        );

        roomGrid[0] = [];
        roomGrid[0][0] = EXIT_ROOM_CELL_TYPE;

        const occupiedCells: Array<[number, number]> = [[0, 0]];
        const growthDirections: ReadonlyArray<[number, number]> = [[0, 1], [0, -1], [1, 0], [-1, 0]];

        while (occupiedCells.size() < targetRoomCount) {
            const [sourceColumn, sourceRow] = occupiedCells[math.floor(math.random() * occupiedCells.size())];
            const [gridColumnDelta, gridRowDelta] = this.shuffleFunction(growthDirections)[0];
            const neighborColumn = sourceColumn + gridColumnDelta;
            const neighborRow = sourceRow + gridRowDelta;
            if (neighborColumn < 0 || neighborRow < 0) continue;
            if (ProceduralRoomGrid.hasRoomInGrid(roomGrid, neighborColumn, neighborRow)) continue;
            if (!roomGrid[neighborColumn]) roomGrid[neighborColumn] = [];
            const assignedRoomType = registeredRoomTypeNames[math.floor(math.random() * registeredRoomTypeNames.size())];
            roomGrid[neighborColumn][neighborRow] = assignedRoomType;
            occupiedCells.push([neighborColumn, neighborRow]);
        }

        return roomGrid;
    }
    private collectMergedWallsForCell(
        passages: Set<string>,
        mergedWalls: Set<string>,
        mergeWallChance: number,
        gridColumn: number,
        gridRow: number
    ): void {
        const mergeCheckDirections: ReadonlyArray<[number, number]> = [[0, 1], [1, 0]];
        for (const [gridColumnDelta, gridRowDelta] of mergeCheckDirections) {
            const neighborColumn = gridColumn + gridColumnDelta;
            const neighborRow = gridRow + gridRowDelta;
            if (!this.hasRoom(neighborColumn, neighborRow)) continue;
            const sharedWallKey = mazePassageKey(gridColumn, gridRow, neighborColumn, neighborRow);
            if (passages.has(sharedWallKey)) continue;
            if (math.random() >= mergeWallChance) continue;
            mergedWalls.add(sharedWallKey);
        }
    }

    private generateMergedWalls(passages: Set<string>, mergeWallChance: number): Set<string> {
        const mergedWalls = new Set<string>();
        for (let gridColumn = 0; gridColumn < this.roomGrid.size(); gridColumn++) {
            const roomRow = this.roomGrid[gridColumn];
            if (!roomRow) continue;
            for (let gridRow = 0; gridRow < roomRow.size(); gridRow++) {
                if (!this.hasRoom(gridColumn, gridRow)) continue;
                this.collectMergedWallsForCell(passages, mergedWalls, mergeWallChance, gridColumn, gridRow);
            }
        }
        return mergedWalls;
    }

    private computeSingleFaceData(
        passages: Set<string>,
        mergedWalls: Set<string>,
        gridColumn: number,
        gridRow: number,
        gridColumnDelta: number,
        gridRowDelta: number,
        thisFace: WallFace
    ): WallFaceData {
        const neighborColumn = gridColumn + gridColumnDelta;
        const neighborRow = gridRow + gridRowDelta;
        const neighborExists = this.hasRoom(neighborColumn, neighborRow);
        const sharedWallKey = mazePassageKey(gridColumn, gridRow, neighborColumn, neighborRow);

        if (neighborExists && mergedWalls.has(sharedWallKey)) return { state: "empty" };
        if (neighborExists && passages.has(sharedWallKey)) return { state: "doorway" };
        if (neighborExists) return { state: "interiorWall" };
        if (this.roomGrid[gridColumn][gridRow] === EXIT_ROOM_CELL_TYPE && thisFace === "north") return { state: "doorway" };
        return { state: "exteriorWall" };
    }

    private computeFaceDataForCell(
        passages: Set<string>,
        mergedWalls: Set<string>,
        gridColumn: number,
        gridRow: number
    ): RoomFaceData {
        return {
            north: this.computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, 0, -1, "north"),
            south: this.computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, 0, 1, "south"),
            east: this.computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, 1, 0, "east"),
            west: this.computeSingleFaceData(passages, mergedWalls, gridColumn, gridRow, -1, 0, "west"),
        };
    }

    private computeAllRoomFaceData(passages: Set<string>, mergedWalls: Set<string>): Map<string, RoomFaceData> {
        const allRoomFaceData = new Map<string, RoomFaceData>();
        for (let gridColumn = 0; gridColumn < this.roomGrid.size(); gridColumn++) {
            const roomRow = this.roomGrid[gridColumn];
            if (roomRow === undefined) continue;
            for (let gridRow = 0; gridRow < roomRow.size(); gridRow++) {
                if (!this.hasRoom(gridColumn, gridRow)) continue;
                allRoomFaceData.set(
                    `${gridColumn},${gridRow}`,
                    this.computeFaceDataForCell(passages, mergedWalls, gridColumn, gridRow)
                );
            }
        }
        return allRoomFaceData;
    }
}