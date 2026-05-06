export function getRandomItemInArray<T>(array: T[]): T {
    return array[math.random(0, array.size() - 1)];
}