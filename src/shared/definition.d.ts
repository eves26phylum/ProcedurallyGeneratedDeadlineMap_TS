export type AnyInstance = WrappedInstance | Instance;
export type EgoMooseExportDraw3DTriangle = [{Size: Vector3, CFrame: CFrame}, {Size: Vector3, CFrame: CFrame}];
export type EgoMooseExportGetBarycentricHeight =  [number | undefined, number, number, number];
export interface EgoMooseFiles {
    draw3dTriangle: (a: Vector3, b: Vector3, c: Vector3) => EgoMooseExportDraw3DTriangle
    getBarycentricHeight: (vertexA: Vector3, vertexB: Vector3, vertexC: Vector3, samplePoint: Vector2) => EgoMooseExportGetBarycentricHeight
}
export interface InstanceAdapter<T extends AnyInstance = AnyInstance> {
    newInstance(this: void, ClassName: keyof CreatableInstances, Parent?: T): T;
    setProperty(this: void, property: T, key: string, value: unknown): void;
    findFirstChild(this: void, target: T, name: string, recursive?: boolean): T | undefined;
    destroy(this: void, instance: T): void;
}
