export namespace deadlineAdapter {
    export function newInstance<T extends keyof CreatableInstances>(className: T, Parent?: WrappedInstance) {
        task.wait();
        return create_instance<T>(className, Parent);
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
}