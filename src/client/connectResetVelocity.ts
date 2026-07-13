import { Logger } from "shared/logger";

export function connectResetVelocity() {
    const Log = new Logger("reset_velocity");
    on_server_event.Connect((args: unknown[]) => {
        const eventType: unknown = args[0];
        assert(typeIs(eventType, "string"), "Event is not a string");
        if (eventType === "reset_velocity") {
            const thisPlayerCharacter = get_chars_root().find_first_child("StarterCharacter");
            if (!thisPlayerCharacter) return;
            const thisHumanoidRootPart: WrappedInstance<Instance> | undefined = thisPlayerCharacter.find_first_child("humanoid_root_part");
            assert(thisHumanoidRootPart && thisHumanoidRootPart.is_a("BasePart"), "Humanoid Root Part is not a BasePart...")
            thisHumanoidRootPart.AssemblyLinearVelocity = Vector3.zero;
            thisHumanoidRootPart.AssemblyAngularVelocity = Vector3.zero;
        }
    })
    Log.info("Listening for server events to reset the character's velocity");
}