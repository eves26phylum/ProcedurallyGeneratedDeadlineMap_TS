export function getRaycast(overrideCFrame: CFrame, distance: number, exclude: WrappedInstance<Instance>[] = [], filterType: Enum.RaycastFilterType = Enum.RaycastFilterType.Exclude) { // function only compatible with deadline
    const camera_cframe = overrideCFrame
    const raycast_params = query.create_raycast_params();
    raycast_params.filter_descendants_instances(exclude);
    raycast_params.filter_type(filterType);
    
    const origin = camera_cframe.Position
    const direction = camera_cframe.LookVector.mul(distance)
    
    const hit = query.raycast(origin, direction, raycast_params)
    
    return hit
}