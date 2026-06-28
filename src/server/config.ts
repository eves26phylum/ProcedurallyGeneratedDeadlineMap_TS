export const NuristanBuildingsConfig = {
    wallPartProps: {
        Material: Enum.Material.Sand,
        Color: Color3.fromRGB(237, 201, 175)
    },
    doorway: {
        width: 2.5,
        height: 6,
        offsetAlongWall: 0,
        bottomOffset: 0
    },
    roomProps: {
        RoomSize: new Vector3(20, 2, 20)
    },
    wall: {
        height: 10,
        thickness: 2
    },
    roomGeneration: {
        minRooms: 2,
        maxRooms: 10,
        mergeWallChance: 0.3
    },
    sniperWindowDoorway: {
        width: 5,
        height: 2,
        bottomOffset: 3,
        offsetAlongWall: 0
    }
}
export const StandardNuristanConfig = {
    grass: () => {
        return {
            Material: Enum.Material.Grass, Color: Color3.fromRGB(158, 201, 33)
        }
    },
    desert: () => { 
        const secondaryAngs = math.random(-20, 10);
        return {Material: Enum.Material.Sand, Color: Color3.fromRGB(237 + secondaryAngs, 201 + math.random(0, 20), 175 + secondaryAngs)}
    }
};
export const TreeConfig = {
    branch: {
        minSize: new Vector2(4, 12),
        maxSize: new Vector2(8, 24),
        props: {
            Material: Enum.Material.Wood,
            Color: Color3.fromRGB(71, 38, 8)
        }
    },
    leaf: {
        minBoxSize: 12,
        maxBoxSize: 32,
        props: {
            Material: Enum.Material.Grass,
            CanCollide: false,
            CanQuery: false,
            Transparency: 0.4,
            Color: Color3.fromRGB(36, 107, 51)
        }
    },
    treesPerTriangle: 4,
    offset: new Vector3(0, -3, 0)
};
export const PART_SIZE = 100;
export const MAP_SIZE = new Vector2(10000, 10000);
export const RESOLUTION = new Vector2(
    math.round(MAP_SIZE.X / PART_SIZE), 
    math.round(MAP_SIZE.Y / PART_SIZE)
);
// export const RESOLUTION = new Vector2(5, 5);
export const ROUGHNESS = 4;
export const PARAMS = {
    lacunarity: 4,
    persistence: 0.25,
    octaves: 2,
    exaggeratedness: 20,
    power: 3,
    scale: math.max(RESOLUTION.X, RESOLUTION.Y) / ROUGHNESS
};
export const POSITION_OFFSET = new Vector3(-(MAP_SIZE.X / 2), 0, -(MAP_SIZE.Y / 2));