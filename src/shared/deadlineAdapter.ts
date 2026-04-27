export namespace deadlineAdapter {
    export function newInstance(className: keyof CreatableInstances, Parent?: WrappedInstance) {
        return create_instance(className, Parent);
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