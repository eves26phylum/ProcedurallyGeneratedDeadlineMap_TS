import { ShuffleFunction, fisherYatesShuffle } from "./Util";

// !deadline-ts.customFinishSector_FinishModulesEnd
// The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.

export function mazePassageKey(firstColumn: number, firstRow: number, secondColumn: number, secondRow: number): string {
    if (firstColumn < secondColumn || (firstColumn === secondColumn && firstRow < secondRow)) {
        return `${firstColumn},${firstRow}|${secondColumn},${secondRow}`;
    }
    return `${secondColumn},${secondRow}|${firstColumn},${firstRow}`;
}

function cellKey(gridColumn: number, gridRow: number): string {
    return `${gridColumn},${gridRow}`;
}

export interface MazeGenerationStrategy {
    generatePassages(
        hasRoom: (gridColumn: number, gridRow: number) => boolean,
        startColumn: number,
        startRow: number
    ): Set<string>;
}

export class DepthFirstMazeSearch implements MazeGenerationStrategy {
    private readonly shuffleFunction: ShuffleFunction;

    constructor(shuffleFunction: ShuffleFunction = fisherYatesShuffle) {
        this.shuffleFunction = shuffleFunction;
    }

    generatePassages(
        hasRoom: (gridColumn: number, gridRow: number) => boolean,
        startColumn: number,
        startRow: number
    ): Set<string> {
        const visitedCells = new Set<string>();
        const passages = new Set<string>();
        this.search(hasRoom, startColumn, startRow, visitedCells, passages);
        return passages;
    }

    private search(
        hasRoom: (gridColumn: number, gridRow: number) => boolean,
        gridColumn: number,
        gridRow: number,
        visitedCells: Set<string>,
        passages: Set<string>
    ): void {
        const adjacencyDeltas: ReadonlyArray<[number, number]> = [[0, -1], [0, 1], [1, 0], [-1, 0]];
        visitedCells.add(cellKey(gridColumn, gridRow));
        for (const [gridColumnDelta, gridRowDelta] of this.shuffleFunction(adjacencyDeltas)) {
            const neighborColumn = gridColumn + gridColumnDelta;
            const neighborRow = gridRow + gridRowDelta;
            if (!hasRoom(neighborColumn, neighborRow)) continue;
            if (visitedCells.has(cellKey(neighborColumn, neighborRow))) continue;
            passages.add(mazePassageKey(gridColumn, gridRow, neighborColumn, neighborRow));
            this.search(hasRoom, neighborColumn, neighborRow, visitedCells, passages);
        }
    }
}