export namespace robloxAdapter {
    function newInstance(className: keyof CreatableInstances, Parent?: Instance) {
        return new Instance(className, Parent);
    }
    function setProperty(property: Record<any, any>, key: any, value: any) {
        property[key] = value;
    }
    function findFirstChild(target: Instance, targetName: string, recursive?: boolean) {
        return target.FindFirstChild(targetName, recursive);
    }
    function destroy(target: Instance) {
        return target.Destroy();
    }
}