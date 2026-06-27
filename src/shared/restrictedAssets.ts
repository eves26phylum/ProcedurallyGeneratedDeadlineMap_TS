// -- CLASS: PROPRIETARY
class RestrictionChecker {
    isRestricted(instance: WrappedInstance) {
        let message = "";
        let restricted = false;
        try {
            const _ = instance.Parent;
        } catch (e) {
            message = tostring(e);
            restricted = true;
        }
        return { message, restricted };
    }
}

class ParentTraverser {
    constructor(public readonly checker: RestrictionChecker) {}

    traverse<T>(
        instance: WrappedInstance,
        callback: (instance: WrappedInstance, parent: WrappedInstance) => T | undefined
    ): T | undefined {
        if (this.checker.isRestricted(instance).restricted) return undefined;
        const parent = instance.Parent;
        if (!parent) return undefined;
        const result = callback(instance, parent);
        if (result !== undefined) return result;
        return this.traverse(parent, callback);
    }
}

class IgnoreFolderFinder {
    constructor(
        public readonly traverser: ParentTraverser,
        public readonly checker: RestrictionChecker
    ) {}

    getIgnoreFolderUsingTaggedChildren(
        proprietaryLogic: (finder: IgnoreFolderFinder, instance: WrappedInstance, parent: WrappedInstance) => [string, WrappedInstance] | undefined
    ): Record<string, WrappedInstance> {
        const candidates: Record<string, WrappedInstance> = {};
        for (const tagString of tags.get_tags()) {
            for (const instance of tags.get_tagged(tagString)) {
                const result = this.traverser.traverse(instance, (inst, parent) =>
                    proprietaryLogic(this, inst, parent)
                );
                if (!result) continue;
                const [key, candidate] = result;
                candidates[key] = candidate;
            }
        }
        return candidates;
    }
}

const checker = new RestrictionChecker();
const traverser = new ParentTraverser(checker);
const finder = new IgnoreFolderFinder(traverser, checker);
export const candidates = finder.getIgnoreFolderUsingTaggedChildren(
    (finder, instance, parent) => {
        const result = finder.checker.isRestricted(parent);
        if (result.restricted && string.find(result.message, "is not accessible")) {
            return [parent.Name, parent];
        }
        return undefined;
    }
);