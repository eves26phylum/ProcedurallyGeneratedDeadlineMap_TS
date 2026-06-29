export const isDeadline = string.find(_VERSION, "{deadline-ts", 1, true)[0] !== undefined;
//local _VERSION = _VERSION.." {deadline-ts PRE-RELEASE}"