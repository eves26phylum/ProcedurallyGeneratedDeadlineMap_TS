import { Logger } from "shared/logger";

export const system_administrator = [sharedvars.vip_owner];
const Log = new Logger("log_to_system_administrator");
export function sendMessageToSystemAdministrators(message: string, system_administrators: string[]) {
    system_administrators.forEach((player_name: string) => {
        const playerFromSystemAdministratorString = players.get(player_name);
        if (!playerFromSystemAdministratorString) return Log.error(`System administrator query did not succeed, no player was found from players.get(${system_administrators.map((player_name: string) => `"${player_name}"`).join(", ")})`);
        playerFromSystemAdministratorString.fire_client("log", message);
    });
}