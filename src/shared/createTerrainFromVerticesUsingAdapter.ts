import { AnyInstance, EgoMooseFiles, InstanceAdapter } from "./definition";
import { assign } from "./Util";
import { returnFunctionWithIdentity } from "./selfProp";

// modules go above
// !deadline-ts.customFinishSector_FinishModulesEnd

export interface WedgeCell {
    triangles: [[AnyInstance, AnyInstance], [AnyInstance, AnyInstance]];
    data: {
        vertices: [Vector3, Vector3, Vector3, Vector3];
        averageHeight: number;
        averageHeightSized: number;
    };
}

export class createTerrain {
    operateOnData?: (cell: WedgeCell) => void;
    EgoMoose: EgoMooseFiles;
    adapter: InstanceAdapter;

    constructor(
        operateOnData: ((cell: WedgeCell) => void) | undefined,
        EgoMoose: EgoMooseFiles,
        adapter: InstanceAdapter,
        materialiseTriangle?: (a: Vector3, b: Vector3, c: Vector3) => [AnyInstance, AnyInstance]
    ) {
        this.materialiseTriangle = materialiseTriangle || this.materialiseTriangle;
        this.adapter = adapter;
        this.operateOnData = operateOnData;
        this.EgoMoose = EgoMoose;
    }

    materialiseTriangle(a: Vector3, b: Vector3, c: Vector3): [AnyInstance, AnyInstance] {
        const [AData, BData] = this.EgoMoose.draw3dTriangle(a, b, c);
        const WedgeA = this.adapter.newInstance("WedgePart");
        const WedgeB = this.adapter.newInstance("WedgePart");
        this.adapter.setProperty(WedgeA, "Anchored", true);
        this.adapter.setProperty(WedgeB, "Anchored", true);
        assign(WedgeA, AData, returnFunctionWithIdentity(this.adapter.setProperty, this.adapter));
        assign(WedgeB, BData, returnFunctionWithIdentity(this.adapter.setProperty, this.adapter));
        return [WedgeA, WedgeB];
    }

    createTrianglesFromData(
        data: number[],
        resolution: Vector2,
        partSize: number,
        offsetVector3: Vector3
    ): Record<number, Record<number, WedgeCell>> {
        const getFromXY = (x: number, y: number): number => {
            return data[x * (resolution.Y + 1) + y];
        };

        const multiplyVectorByPartSize = (x: number, y: number, h: number): Vector3 => {
            return new Vector3(x * partSize, h * partSize, y * partSize);
        };

        let minSize = math.huge;
        let maxSize = -math.huge;

        for (let x = 0; x < resolution.X; x++) {
            for (let y = 0; y < resolution.Y; y++) {
                const val = getFromXY(x, y);
                if (val < minSize) minSize = val;
                if (val > maxSize) maxSize = val;
            }
        }

        const minSizeVector3 = new Vector3(0, minSize * partSize, 0);
        const wedges: Record<number, Record<number, WedgeCell>> = {};

        for (let x = 0; x < resolution.X; x++) {
            for (let y = 0; y < resolution.Y; y++) {
                const topLeftOffset = new Vector2(0, 0);
                const topRightOffset = new Vector2(1, 0);
                const bottomLeftOffset = new Vector2(0, 1);
                const bottomRightOffset = new Vector2(1, 1);

                const tLTotalH = getFromXY(x + topLeftOffset.X, y + topLeftOffset.Y);
                const tRTotalH = getFromXY(x + topRightOffset.X, y + topRightOffset.Y);
                const bLTotalH = getFromXY(x + bottomLeftOffset.X, y + bottomLeftOffset.Y);
                const bRTotalH = getFromXY(x + bottomRightOffset.X, y + bottomRightOffset.Y);

                const topLeft = multiplyVectorByPartSize(x + topLeftOffset.X, y + topLeftOffset.Y, tLTotalH).add(offsetVector3).sub(minSizeVector3);
                const topRight = multiplyVectorByPartSize(x + topRightOffset.X, y + topRightOffset.Y, tRTotalH).add(offsetVector3).sub(minSizeVector3);
                const bottomLeft = multiplyVectorByPartSize(x + bottomLeftOffset.X, y + bottomLeftOffset.Y, bLTotalH).add(offsetVector3).sub(minSizeVector3);
                const bottomRight = multiplyVectorByPartSize(x + bottomRightOffset.X, y + bottomRightOffset.Y, bRTotalH).add(offsetVector3).sub(minSizeVector3);

                if (!wedges[x]) wedges[x] = {};

                const cell: WedgeCell = {
                    triangles: [
                        this.materialiseTriangle(topLeft, topRight, bottomLeft) as [AnyInstance, AnyInstance],
                        this.materialiseTriangle(topRight, bottomRight, bottomLeft) as [AnyInstance, AnyInstance],
                    ],
                    data: {
                        vertices: [topLeft, topRight, bottomLeft, bottomRight],
                        averageHeight: getFromXY(x, y) / maxSize,
                        averageHeightSized: getFromXY(x, y),
                    }
                };

                wedges[x][y] = cell;

                if (!this.operateOnData) continue;
                this.operateOnData(cell);
            }
        }

        return wedges;
    }
}