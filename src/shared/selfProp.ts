export function returnFunctionWithIdentity(func: (...args: any) => any, _self: any) {
    assert(func, "Function is missing")
    assert(_self, "_self is missing")
    return function(...args: unknown[]) {return func(_self, ...args) }
}