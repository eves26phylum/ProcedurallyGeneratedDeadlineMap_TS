export const isDeadline = string.find(_VERSION, "{deadline-ts", 1, true) !== undefined;
print(isDeadline)
//local _VERSION = _VERSION.." {deadline-ts PRE-RELEASE}"