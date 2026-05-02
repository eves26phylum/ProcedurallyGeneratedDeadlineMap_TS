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
export type ShuffleFunction = <T>(inputArray: ReadonlyArray<T>) => T[];
export function fisherYatesShuffle<T>(inputArray: ReadonlyArray<T>): T[] {
    const result = [...inputArray];
    for (let currentIndex = result.size() - 1; currentIndex > 0; currentIndex--) {
        const randomSwapIndex = math.floor(math.random() * (currentIndex + 1));
        const elementAtCurrentIndex = result[currentIndex];
        result[currentIndex] = result[randomSwapIndex];
        result[randomSwapIndex] = elementAtCurrentIndex;
    }
    return result;
}