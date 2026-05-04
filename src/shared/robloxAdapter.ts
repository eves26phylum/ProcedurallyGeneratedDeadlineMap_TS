const CollectionService = game?.GetService("CollectionService");
export namespace robloxAdapter {
    export function newInstance<T extends keyof CreatableInstances>(className: T, Parent?: Instance) {
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
    export function addTag(target: Instance, tag: string) {
        if (!CollectionService) return;
        CollectionService.AddTag(target, tag);
    }
    export function isA<C extends keyof Instances>(target: Instance, whatClass: C): target is Instance & Instances[C] {
        return target.IsA(whatClass);
    }
    export function playSound(target: Sound) {
        target.Play();
    }
}