import { isDeadline } from "./isDeadline";
// !deadline-ts.customFinishSector_FinishModulesEnd

export function getWorldRoot() { return isDeadline ? get_map_root() : game.GetService("Workspace"); }