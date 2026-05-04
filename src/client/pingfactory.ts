import { AnyInstance, InstanceAdapter } from "shared/definition";
import { worldRoot } from "shared/getRoot";
// !deadline-ts.customFinishSector_FinishModulesEnd
export class PingUIItem {
    adapter: InstanceAdapter;

    constructor(adapter: InstanceAdapter) {
        this.adapter = adapter;
    }

    build(position: Vector3, parent?: AnyInstance): AnyInstance<Part> {
        const part = this.adapter.newInstance("Part", parent ?? worldRoot);
        this.adapter.setProperty(part, "Size", new Vector3(1, 1, 1));
        this.adapter.setProperty(part, "Position", position);
        this.adapter.setProperty(part, "Anchored", true);
        this.adapter.setProperty(part, "Transparency", 1);
        this.adapter.setProperty(part, "CanCollide", false);
        this.adapter.setProperty(part, "CastShadow", false);

        const billboard = this.adapter.newInstance("BillboardGui", part);
        this.adapter.setProperty(billboard, "AlwaysOnTop", true);
        this.adapter.setProperty(billboard, "ClipsDescendants", false);
        this.adapter.setProperty(billboard, "LightInfluence", 0);
        this.adapter.setProperty(billboard, "Size", new UDim2(0, 12, 0, 12));

        const dot = this.adapter.newInstance("Frame", billboard);
        this.adapter.setProperty(dot, "Size", new UDim2(1, 0, 1, 0));
        this.adapter.setProperty(dot, "AnchorPoint", new Vector2(0.5, 0.5));
        this.adapter.setProperty(dot, "Position", new UDim2(0.5, 0, 0.5, 0));
        this.adapter.setProperty(dot, "BackgroundColor3", Color3.fromRGB(255, 80, 80));
        this.adapter.setProperty(dot, "BackgroundTransparency", 0.9);
        this.adapter.setProperty(dot, "BorderSizePixel", 0);

        const corner = this.adapter.newInstance("UICorner", dot);
        this.adapter.setProperty(corner, "CornerRadius", new UDim(1, 0));

        const stroke = this.adapter.newInstance("UIStroke", dot);
        this.adapter.setProperty(stroke, "Color", Color3.fromRGB(255, 255, 255));
        this.adapter.setProperty(stroke, "Thickness", 2);
        this.adapter.setProperty(stroke, "Transparency", 0.7);

        return part;
    }
    destroy(part: AnyInstance<Part>) {
        this.adapter.destroy(part);
    }
}

export class PingNoisePlayer {
    adapter: InstanceAdapter;
    soundId: string;
    constructor(adapter: InstanceAdapter, soundId?: string) {
        this.adapter = adapter;
        this.soundId = soundId || "rbxassetid://17208204604";
    }
    play(): void {
        const newSound = this.adapter.newInstance("Sound");
        this.adapter.setProperty(newSound, "SoundId", this.soundId);
        this.adapter.playSound(newSound);
        task.delay(newSound.TimeLength, () => {
            this.adapter.destroy(newSound);
        })
    }
}

export class Ping {
    private uiItem: PingUIItem;
    private noisePlayer: PingNoisePlayer;
    private lastingTime: number;

    constructor(uiItem: PingUIItem, noisePlayer: PingNoisePlayer, lastingTime: number) {
        this.uiItem = uiItem;
        this.noisePlayer = noisePlayer;
        this.lastingTime = lastingTime;
    }

    play(position: Vector3): void {
        task.defer(() => {
            this.noisePlayer.play();
            const part = this.uiItem.build(position);
            task.delay(this.lastingTime, () => {
                this.uiItem.destroy(part);
            });
        });
    }
}