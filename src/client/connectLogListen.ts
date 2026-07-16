import { Logger } from "shared/logger";

export function connectLogListen() {
    const Log = new Logger("log");
    on_server_event.Connect((args: unknown[]) => {
        const eventType: unknown = args[0];
        assert(typeIs(eventType, "string"), "Event is not a string");
        if (eventType === "log") {
            const logMessage = args[1];
            assert(typeIs(logMessage, "string"), "Log message is not a string");
            Log.log(logMessage);
        }
    })
}