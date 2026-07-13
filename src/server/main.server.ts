import { Logger } from "shared/logger";
import { initialise_game } from "./initialise_game";

const Log = new Logger("main");
//connect();
Shared.should_initialise_game = true;
on_client_event.Connect((playerName: string, args: unknown[]) => {
    const player = players.get(playerName);
    if (!player) return;
    const eventType = args[0];
    if (!typeIs(eventType, "string")) return player.kick();
    if (eventType !== "initialise_game") return;
    if (!Shared.should_initialise_game) {
        return player.fire_client("initialise", false);
    }
    Shared.should_initialise_game = false;
    player.fire_client("initialise", true);
    const Log = new Logger("main::initialise_game");
    Log.log(playerName, "has started the initialisation function.")
    initialise_game();
    Log.log("initialise_game has finished");
})