export namespace robloxAdapter {
    export function newInstance(className: keyof CreatableInstances, Parent?: Instance) {
        return new Instance(className, Parent);
    }
    export function setProperty(property: Record<any, any>, key: any, value: any) {
        property[key] = value;
    }
    export function findFirstChild(target: Instance, targetName: string, recursive?: boolean) {
        return target.FindFirstChild(targetName, recursive);
    }
    export function destroy(target: Instance) {
        return target.Destroy();
    }
}