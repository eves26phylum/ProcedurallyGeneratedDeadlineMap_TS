import { assign } from "./Util"
// !deadline-ts.customFinishSector_FinishModulesEnd

export type LogTypes = {
    print: (...args: defined[]) => void,
    warn: (...args: defined[]) => void,
    info: (...args: defined[]) => void,
    error: (...args: defined[]) => void
}
export const DefaultLogTypes = {
    print: print,
    warn: warn,
    info: info || print,
    error: error
}
export class Logger {
    name: string
    funcs: LogTypes
    constructor(name: string, funcs: Partial<LogTypes> = {}) {
        this.name = name;
        const funcer: LogTypes = assign({} as LogTypes, DefaultLogTypes); // oops i mistyped assign so I have to do as. Whatever.
        this.funcs = assign<LogTypes>(funcer, funcs);
    }
    private useFuncToLogMessage(func: (...args: defined[]) => void, message: defined[]) {
        message.forEach((thisLine: defined, index: number) => {
            func(`   ${index}. ${thisLine}`);
        })
    }
    log(...message: defined[]) {
        this.funcs.print(`[${this.name}]`)
        this.useFuncToLogMessage(this.funcs.print, [...message]);
    }
    warn(...message: defined[]) {
        this.funcs.warn(`[${this.name}]`);
        this.useFuncToLogMessage(this.funcs.warn, [...message]);
    }
    error(...message: defined[]) {
        this.funcs.error(`[${this.name}]`)
        this.useFuncToLogMessage(this.funcs.error, [...message]);
    }
    info(...message: defined[]) {
        this.funcs.info(`[${this.name}]`)
        this.useFuncToLogMessage(this.funcs.info, [...message]);
    }
}