import { EgoMoose } from "shared/EgoMoose";
import { AnyInstance, EgoMooseFiles } from "../shared/definition";

// modules go above
// !deadline-ts.customFinishSector_FinishModulesEnd

export function materialiseTriangle(a: Vector3, b: Vector3, c: Vector3) {
    const [AData, BData] = EgoMoose.draw3dTriangle(a, b, c);
    local WedgeA = adapter:newInstance("WedgePart")
    local WedgeB = adapter:newInstance("WedgePart")
    adapter:setProperty(WedgeA, "Anchored", true)
    adapter:setProperty(WedgeB, "Anchored", true)
    Util:assign(WedgeA, AData, selfProp:returnFunctionWithIdentity(adapter.setProperty, adapter))
    Util:assign(WedgeB, BData, selfProp:returnFunctionWithIdentity(adapter.setProperty, adapter))
    return WedgeA, WedgeB
}
export class createTerrain {
    materialiseTriangle: (a: Vector3, b: Vector3, c: Vector3) => [AnyInstance, AnyInstance]
    operateOnData: () => void
    EgoMoose: EgoMooseFiles
    
    constructor(materialiseTriangle: () => [AnyInstance, AnyInstance], operateOnData: () => void, EgoMoose: EgoMooseFiles) {
        this.materialiseTriangle = materialiseTriangle;
        this.operateOnData = operateOnData;
        this.EgoMoose = EgoMoose;
    }
    createTrianglesFromData(data: number[], resolution: Vector2, partSize: number, offsetVector3: Vector3) {
        
    }
}