// local translateTerrainOrientationForStructureBonding = {
//     orientationSubtraction = Vector3.new(0, 0, -90)
// }
// -- the maximum degree a person could live in is 15°
// --[[
// NOTES:
// -- Priority order for each structure
// (trees are default structure that generate at last priority)
// Buildings are first, and generate on any incline less than 15°
// So after the building does not generate on that triangle (it can occupy multiple triangles if needed), the tree generates
// A position map of already generated structures on what triangle also exists
// ]]
// function translateTerrainOrientationForStructureBonding:Translate(targetTriangle)
//     local orientation = targetTriangle.Orientation
// 	return Vector3.new(orientation.X, orientation.Y, orientation.Z) + self.orientationSubtraction
// end
// function translateTerrainOrientationForStructureBonding:GetSteepnessInDegrees(targetCFrame)
//     local angle = math.acos(targetCFrame.UpVector:Dot(Vector3.new(0, 1, 0)))
//     return math.deg(angle)
// end
// return translateTerrainOrientationForStructureBonding

export interface translateTerrainOrientationForStructureBondingConfig {
    orientationSubtraction: Vector3;
}
export class translateTerrainOrientationForStructureBonding {
    config: translateTerrainOrientationForStructureBondingConfig
    constructor(config: translateTerrainOrientationForStructureBondingConfig) {
        this.config = config;
    }
    Translate(targetTriangleOrientation: Vector3) {
        return new Vector3(targetTriangleOrientation.X, targetTriangleOrientation.Y, targetTriangleOrientation.Z).add(this.config.orientationSubtraction);
    }
    GetSteepnessInDegrees(targetCFrame: CFrame) {
        const angle = math.acos(targetCFrame.UpVector.Dot(new Vector3(0, 1, 0)));
        return math.deg(angle);
    }
}