function FUCKROBLOX(a: number): number {
    // fuck roblox basically fucks roblox and also avoids integer noise
    if (math.floor(a) === a) {
        return a + 0.001;
    }
    return a;
}

export class PerlinNoise {
    generate(
        scale: number,
        resolution: Vector2,
        offset: Vector2 | undefined,
        exaggeratedness: number,
        lacunarity: number,
        persistence: number,
        octaves: number,
        POWER: number
    ): number[] {
        const resolvedOffset = offset ?? new Vector2(0, 0);
        const noiseMap: number[] = [];
        let minRaw = math.huge;
        let maxRaw = -math.huge;

        for (let x = 0; x <= resolution.X; x++) {
            for (let y = 0; y <= resolution.Y; y++) {
                const offsetX = x + resolvedOffset.X;
                const offsetY = y + resolvedOffset.Y;
                let frequency = 1;
                let amplitude = 1;
                let noiseHeight = 0;

                for (let i = 0; i < octaves; i++) {
                    const sampleX = (offsetX / scale) * frequency;
                    const sampleY = (offsetY / scale) * frequency;
                    const computedNoise = math.noise(
                        FUCKROBLOX(sampleX),
                        FUCKROBLOX(sampleY)
                    );
                    const clampedNoise = computedNoise / 2 + 0.5;
                    noiseHeight += clampedNoise * amplitude;
                    amplitude *= persistence;
                    frequency *= lacunarity;
                }

                const endHeight = (noiseHeight ** POWER) * exaggeratedness;
                if (endHeight < minRaw) minRaw = endHeight;
                if (endHeight > maxRaw) maxRaw = endHeight;
                noiseMap.push(endHeight);
            }
        }

        return noiseMap;
    }
}