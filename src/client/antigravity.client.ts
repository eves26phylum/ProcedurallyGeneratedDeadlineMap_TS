framework.on_spawned.Connect(() => {
    const thisPlayer = get_chars_root().find_first_child("StarterCharacter");
    assert(thisPlayer, "This player's character does not exist");
    const humanoid_root_part = thisPlayer.find_first_child("humanoid_root_part");
    assert(humanoid_root_part && humanoid_root_part.is_a("BasePart"), `This humanoid root part does not exist or is wrong type. ${humanoid_root_part ? `ClassName is: ${humanoid_root_part.ClassName}` : ""}`)
    const body_force = create_instance("BodyForce");
    body_force.Force = new Vector3(0, -((60 - sharedvars.sv_gravity) * humanoid_root_part.AssemblyMass), 0);
    body_force.Parent = humanoid_root_part;
})