export namespace deadlineAdapter {
    function newInstance(className: keyof CreatableInstances, Parent?: WrappedInstance) {
        return create_instance(className, Parent);
    }
    function setProperty(property: Record<any, any>, key: any, value: any) {
        property[key] = value;
    }
    function findFirstChild(target: WrappedInstance, targetName: string, recursive?: boolean) {
        return target.find_first_child(targetName, recursive);
    }
    function destroy(target: WrappedInstance) {
        return target.destroy();
    }
}