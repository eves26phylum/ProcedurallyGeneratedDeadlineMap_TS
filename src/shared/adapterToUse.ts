import { isDeadline } from "./isDeadline";
import { InstanceAdapter } from "./definition";
import { deadlineAdapter } from "./deadlineAdapter";
import { robloxAdapter } from "./robloxAdapter";
// !deadline-ts.customFinishSector_FinishModulesEnd

export const adapterToUse: InstanceAdapter = isDeadline ? deadlineAdapter : robloxAdapter;