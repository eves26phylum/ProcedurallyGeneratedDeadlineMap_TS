function assign<T extends object>( // Util for js Object.assign
    a: T, 
    b: Record<string, any>, 
    optionalFunc: (a: T, index: string, value: any) => void = (a, index, value) => {
        (a as Record<string, any>)[index] = value;
    }
) {
    for (const [index, value] of pairs(b)) {
        optionalFunc(a, index, value);
    }
    return a;
}

export interface AssetPreloaderAsset {
    preload(): void
}
export interface CheckValidator {
    validate(): boolean
}
export class ThresholdUtility implements CheckValidator {
    threshold: number
    readonly upperLimits: number
    constructor(upperLimits: number) {
        this.threshold = 0;
        this.upperLimits = upperLimits;
    }
    validate() {
        this.threshold += 1;
        if (this.threshold > this.upperLimits) return true;
        return false;
    }
}
function CheckUntil(validatorFunction: () => unknown) {
    while (!validatorFunction()) {
        task.wait();
    }
}
export class AudioAsset implements AssetPreloaderAsset { // ts: AudioAsset implements AssetPreloaderAsset
    object: WrappedInstance<Sound>
    thisThresholdUtility: ThresholdUtility
    constructor(props: Partial<InstanceProperties<Sound>>, thresholdUtility: ThresholdUtility) {
        this.object = sound.create();
        this.object.Volume = 0;
        this.thisThresholdUtility = thresholdUtility;
        assign(this.object, props);
    }
    preload() {
        this.object.play();
        // const thisThresholdUtility = new ThresholdUtility(60); don't hardcode
        CheckUntil(() => {
            const isPastTimeLimit = this.thisThresholdUtility.validate();
            const isTheSoundLoadedYetImBored = this.object.TimeLength !== 0;
            return isPastTimeLimit || isTheSoundLoadedYetImBored;
        })
        // this.object.destroy();
        task.delay(this.object.TimeLength + 1, () => { 
			this.object.destroy()
        })
    }
}
export class AssetPreloader {
    assets: AssetPreloaderAsset[]
    constructor(assets: AssetPreloaderAsset[]) {
        this.assets = assets;
    }
    preloadAll() {
        let preloadedCounter = 0;
        this.assets.forEach((thisAssetPreloaderAsset: AssetPreloaderAsset, index: number) => {
            task.defer(() => {
                thisAssetPreloaderAsset.preload();
                preloadedCounter++;
            });
        })
        while (preloadedCounter < this.assets.size()) {
            task.wait();
        }
    }
}

//new AudioAsset({}, new ThresholdUtility(60));