import { Logger } from "shared/logger";
import { bindRecoilCam } from "./superShakeRecoil";
import { connectUILogic } from "./connectUI";
import { connectPingLogic } from "./connectPing";
import { connectDroneLogic } from "./connectDrone";
import { AssetPreloader, AudioAsset, ThresholdUtility } from "./assetPreloader";
import { connectResetVelocity } from "./connectResetVelocity";
// !deadline-ts.customFinishSector_FinishModulesEnd
const Log = new Logger("main");
const PingAssetPreloader = new AssetPreloader(
[
        new AudioAsset({
            SoundId: "rbxassetid://17208204604"
        }, new ThresholdUtility(60))
    ]
);
PingAssetPreloader.preloadAll();

bindRecoilCam(); // for realistic-ish recoil camera
connectDroneLogic(); // connects spectating drones, and listens for pings displayed on drones
connectPingLogic(); // connects ping keybinds, and listens for team pings to display
connectUILogic(); // connects biome status loading ui
connectResetVelocity(); // connects the logic required for you to not fly into the air whenever you spawn

Log.info("Run this command to start the game and map generation!", "shared.initialise_game\"\"")

Shared.initialise_game = () => {
    fire_server("initialise_game");
}