const CollectionService = game?.GetService("CollectionService");
export namespace tagsService {
    export function getTags() {
        return CollectionService ? CollectionService.GetTags() : tags.get_tags();
    }
    export function getTagged(tag: string) {
        return CollectionService ? CollectionService.GetTagged(tag) : tags.get_tagged(tag);
    }
}