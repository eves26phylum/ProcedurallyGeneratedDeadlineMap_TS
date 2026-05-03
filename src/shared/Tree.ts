import { Biome } from "./biome";
import { createTerrain, WedgeCell } from "./createTerrainFromVerticesUsingAdapter";
import { AnyInstance, InstanceAdapter } from "./definition";
import { EgoMoose } from "./EgoMoose";
import { ensureStructureData, structureClaimLand, useStructureData } from "./structure";
import { assign } from "./Util";
// !deadline-ts.customFinishSector_FinishModulesEnd

export interface TreeConfig {
    branch: {
        minSize: Vector2,
        maxSize: Vector2,
        props: Partial<InstanceProperties<Part>>
    }
    leaf: {
        minBoxSize: number,
        maxBoxSize: number,
        props: Partial<InstanceProperties<Part>>
    }
}
export class Tree implements Biome {
    priority: number;
    name: string;
    adapter: InstanceAdapter;
    config: TreeConfig;
    parent: AnyInstance;

    constructor(adapterToUse: InstanceAdapter, config: TreeConfig, parent: AnyInstance) {
        this.adapter = adapterToUse;
        this.name = "Tree";
        this.priority = 30;
        this.config = config;
        this.parent = parent;
    }

    private getRandomSurfacePosition(vertices: [Vector3, Vector3, Vector3]): Vector3 | undefined {
        const toXZ = (v: Vector3) => new Vector2(v.X, v.Z);
        const randomPoint = EgoMoose.getPointFromWeights(
            toXZ(vertices[0]),
            toXZ(vertices[1]),
            toXZ(vertices[2]),
            EgoMoose.getRandomWeights()
        );
        const [height] = EgoMoose.getBarycentricHeight(vertices[0], vertices[1], vertices[2], randomPoint);
        if (height === undefined) return undefined;
        return new Vector3(randomPoint.X, height, randomPoint.Y);
    }

    private createTree(positionToPlaceAt: Vector3, thisBranchSize: Vector3, thisBallSize: Vector3) {
        const cylinder = this.adapter.newInstance("Part");
        this.adapter.setProperty(cylinder, "Anchored", true);
        this.adapter.setProperty(cylinder, "Shape", Enum.PartType.Cylinder);
        this.adapter.setProperty(cylinder, "Size", thisBranchSize);
        this.adapter.setProperty(cylinder, "CFrame", CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90)).add(positionToPlaceAt.add(new Vector3(0, thisBranchSize.Y / 2, 0))));
        this.adapter.setProperty(cylinder, "Parent", this.parent);
        this.adapter.setProperty(cylinder, "Name", "Branch");
        assign(cylinder, this.config.branch.props, this.adapter.setProperty);
        const leaf = this.adapter.newInstance("Part");
        this.adapter.setProperty(leaf, "Anchored", true);
        this.adapter.setProperty(leaf, "Shape", Enum.PartType.Ball);
        this.adapter.setProperty(leaf, "Size", thisBallSize);
        this.adapter.setProperty(leaf, "Position", positionToPlaceAt.add(new Vector3(0, thisBranchSize.Y * 2, 0))); // half of the ball is leaking up
        this.adapter.setProperty(leaf, "Parent", this.parent);
        assign(leaf, this.config.leaf.props, this.adapter.setProperty);
    }

    generate(yourSelf: createTerrain, yourCell: WedgeCell) {
        if (useStructureData(yourCell)) return;
        const [branchMaxSize, branchMinSize] = [this.config.branch.maxSize, this.config.branch.minSize];
        const randY = branchMinSize.Y + math.random() * (branchMaxSize.Y - branchMinSize.Y);
        const randX = branchMinSize.X + math.random() * (branchMaxSize.X - branchMinSize.X);
        const thisBranchSize = new Vector3(randY, randX, randX);
        const randLeafSize = this.config.leaf.minBoxSize + math.random() * (this.config.leaf.maxBoxSize - this.config.leaf.minBoxSize);
        const thisLeafSize = new Vector3(randLeafSize, randLeafSize, randLeafSize);
        
        const pos1 = this.getRandomSurfacePosition(yourCell.verticesForTriangles[0]);
        const pos2 = this.getRandomSurfacePosition(yourCell.verticesForTriangles[1]);
        
        if (pos1 === undefined || pos2 === undefined) return;
        this.createTree(pos1, thisBranchSize, thisLeafSize);
        this.createTree(pos2, thisBranchSize, thisLeafSize);
        ensureStructureData(yourCell);
        structureClaimLand(this, yourCell);
    }
}