export function assign<T extends object>(
    a: T, 
    b: Record<string, any>, 
    optionalFunc: (a: T, index: any, value: any) => void = (a, index, value) => {
        (a as Record<any, any>)[index] = value;
    }
) {
    assert(a, "A is missing");
    assert(b, "B is missing");
    
    for (const [index, value] of pairs(b)) {
        optionalFunc(a, index, value);
    }
    return a;
}
