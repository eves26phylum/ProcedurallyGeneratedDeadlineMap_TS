let wagesCounter = 0;
export namespace deadlineAdapter {
    export function newInstance<T extends keyof CreatableInstances>(className: T, Parent?: WrappedInstance) {
        if (wagesCounter > 1000) {
            wagesCounter = 0;
            task.wait(0.05);
        }
        wagesCounter++;
        const thisInstance = create_instance<T>(className);
        if (Parent) thisInstance.Parent = Parent;
        return thisInstance;
    }
    export function setProperty(property: Record<any, any>, key: any, value: any) {
        property[key] = value;
    }
    export function findFirstChild(target: WrappedInstance, targetName: string, recursive?: boolean) {
        return target.find_first_child(targetName, recursive);
    }
    export function destroy(target: WrappedInstance) {
        return target.destroy();
    }
    export function addTag(target: WrappedInstance, tag: string) {
        target.add_tag(tag);
    }
    export function isA<C extends keyof Instances>(target: WrappedInstance, whatClass: C): target is WrappedInstance & Instances[C] {
        return target.is_a(whatClass);
    }
    export function playSound(target: WrappedInstance<Sound>) {
        target.play();
    }
}