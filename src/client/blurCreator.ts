export class BlurCreator {
    private lastBlur: WrappedInstance<BlurEffect> | undefined = undefined;

    destroyBlur(): void {
        if (this.lastBlur) this.lastBlur.destroy();
    }

    createBlur(Lighting: WrappedInstance): WrappedInstance<BlurEffect> {
        this.destroyBlur();
        const blur = create_instance("BlurEffect");
        blur.Size = 0;
        blur.Parent = Lighting;
        this.lastBlur = blur;
        return blur;
    }
}