
export interface PingSystemConfig {
    pingCooldownSeconds: number;
}
// export class RateLimit 
export class PingSystem {
    private readonly lastPingedTimeByPlayerName: Record<string, number | undefined> = {};

    constructor(private readonly config: PingSystemConfig) {}

    handlePlayerPing(player: Player, pingPosition: Vector3, playerDroneName: string): void {
        const lastPingTime = this.lastPingedTimeByPlayerName[player.name] ?? 0;
        if (os.time() - lastPingTime < this.config.pingCooldownSeconds) return;

        this.lastPingedTimeByPlayerName[player.name] = os.time();
        const playerTeam = player.get_team();

        players.get_all().forEach((targetPlayer: Player) => {
            targetPlayer.fire_client("player_ping", playerDroneName);
            if (targetPlayer.get_team() !== playerTeam) return;
            targetPlayer.fire_client("team_ping", pingPosition);
        });
    }
}

        // const player = players.get(playerName);
        // if (!player) return;
        // const eventType = args[0];
        // if (!typeIs(eventType, "string")) return player.kick();
        // if (eventType === "ping_at_position") {
        //     const pingPosition = args[1];
        //     if (!typeIs(pingPosition, "vector")) return player.kick();
        //     const thisLastPingedTime = lastPingedTime[player.name] || 0;

        //     if (os.time() - thisLastPingedTime < 3) return;
        //     lastPingedTime[player.name] = os.time();

        //     players.get_all().forEach((thisPlayer: Player, index: number) => {
        //         thisPlayer.fire_client("player_ping", droneNames[player.name] || "fucking dog");
        //         if (thisPlayer.get_team() !== player.get_team()) return;
        //         thisPlayer.fire_client("team_ping", pingPosition);
        //     })
        // }