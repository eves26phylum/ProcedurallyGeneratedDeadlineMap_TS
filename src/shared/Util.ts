export function assign(a: Record<any, any>, b: Record<any, any>, optionalFunc: (a: Record<any, any>, index: any, value: any) => void = function(a, index, value) { a[index] = value }) {
    assert(a, "A is missing");
    assert(b, "B is missing");
    for (const [index, value] of pairs(b)) {
        optionalFunc(a, index, value)
    }
}