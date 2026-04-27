export type AnyInstance = WrappedInstance | Instance;
export type EgoMooseExportDraw3DTriangle = [{Size: Vector3, CFrame: CFrame}, {Size: Vector3, CFrame: CFrame}];
export type EgoMooseExportGetBarycentricHeight =  [number | undefined, number, number, number];
export interface EgoMooseFiles {
    draw3dTriangle: (a: Vector3, b: Vector3, c: Vector3) => EgoMooseExportDraw3DTriangle
    getBarycentricHeight: (vertexA: Vector3, vertexB: Vector3, vertexC: Vector3, samplePoint: Vector2) => EgoMooseExportGetBarycentricHeight
}
export interface InstanceAdapter {
    newInstance: (ClassName: keyof CheckableTypes, Parent: Instance | undefined) => Instance
    setProperty: (property: AnyInstance, key: string, value: any) => void
    findFirstChild: (target: AnyInstance) => AnyInstance | undefined
}