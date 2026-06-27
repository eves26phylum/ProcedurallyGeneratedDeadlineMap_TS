// -- CLASS: PROPRIETARY
class RestrictionChecker {
    isRestricted(instance: WrappedInstance) {
        let message = "";
        let restricted = false;
        try {
            const _ = instance.Parent;
        } catch (e) {
            message = tostring(e);
            restricted = true;
        }
        return { message, restricted };
    }
}

class ParentTraverser {
    constructor(public readonly checker: RestrictionChecker) {}

    traverse<T>(
        instance: WrappedInstance,
        callback: (instance: WrappedInstance, parent: WrappedInstance) => T | undefined
    ): T | undefined {
        if (this.checker.isRestricted(instance).restricted) return undefined;
        const parent = instance.Parent;
        if (!parent) return undefined;
        const result = callback(instance, parent);
        if (result !== undefined) return result;
        return this.traverse(parent, callback);
    }
}

class IgnoreFolderFinder {
    constructor(
        public readonly traverser: ParentTraverser,
        public readonly checker: RestrictionChecker
    ) {}

    getIgnoreFolderUsingTaggedChildren(
        proprietaryLogic: (finder: IgnoreFolderFinder, instance: WrappedInstance, parent: WrappedInstance) => [string, WrappedInstance] | undefined
    ): Record<string, WrappedInstance> {
        const candidates: Record<string, WrappedInstance> = {};
        for (const tagString of tags.get_tags()) {
            for (const instance of tags.get_tagged(tagString)) {
                const result = this.traverser.traverse(instance, (inst, parent) =>
                    proprietaryLogic(this, inst, parent)
                );
                if (!result) continue;
                const [key, candidate] = result;
                candidates[key] = candidate;
            }
        }
        return candidates;
    }
}

class BlurCreator {
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

const checker = new RestrictionChecker();
const traverser = new ParentTraverser(checker);
const finder = new IgnoreFolderFinder(traverser, checker);
const blurCreator = new BlurCreator();
const candidates = finder.getIgnoreFolderUsingTaggedChildren(
    (finder, instance, parent) => {
        const result = finder.checker.isRestricted(parent);
        if (result.restricted && string.find(result.message, "is not accessible")) {
            return [parent.Name, parent];
        }
        return undefined;
    }
);

assert(candidates.Lighting, "Lighting candidate not found");
framework.on_died.Connect(() => blurCreator.destroyBlur());
export function bindRecoilCam() {
class CustomFreecam {
    get_head_cframe: () => CFrame;
    cam_position: CFrame;
    camera_cframe: CFrame;
    blur: WrappedInstance<BlurEffect>;
    roll?: number;

    rot_x: number;
    rot_y: number;
    min_roll: number;
    max_roll: number;
    real_rot_x: number;
    real_rot_y: number;

    roll_limit_buffer: number;
    recoil_recovery_speed: number;
    look_damping_speed: number;
    recoil_threshold: number;
    recoil_intensity: number;
    blur_intensity: number;
    blur_bound_lower: number;
    blur_bound_upper: number;
    horizontal_vis_multiplier: number;
    horizontal_shake_multiplier: number;
    rot_y_softening: number;
    vertical_recoil_frequency: number;
    lateral_recoil_frequency: number;
    super_recoil_intensity: number;
    sway_frequency: number;
    sway_intensity: number;
    mouse_delta_base_scale: number;
    recoil_lateral_fraction: number;
    recoil_lateral_displacement_scale: number;
    input: {
        movementX: number,
        movementY: number,
        movementZ: number
    };
    t_seed_range: number;
    vertical_shake_base_threshold: number;
    vertical_shake_frequency_scale: number;
    vertical_shake_amplitude_scale: number;
    current_rot_x: number;
    current_rot_y: number;
    t: number;
    vertical_shake_phase: number;
    last_base_recoil: number;

    constructor(get_head_cframe: () => CFrame) {
        this.get_head_cframe = get_head_cframe;

        this.cam_position = new CFrame(-35.25, 200.662, 8.242);
        this.rot_x = 0;
        this.rot_y = 0;
        this.real_rot_x = 0;
        this.real_rot_y = 0;

        this.roll_limit_buffer = 0.2;
        this.recoil_recovery_speed = 0.5;
        this.look_damping_speed = 20;
        this.recoil_threshold = 0.01;
        this.recoil_intensity = 0.03;
        this.current_rot_x = 0;
        this.current_rot_y = 0;
        this.blur_intensity = 150;
        this.input = {
            movementX: 0,
            movementY: 0,
            movementZ: 0
        };
        this.blur_bound_lower = 0;
        this.blur_bound_upper = 5;
        this.horizontal_vis_multiplier = 0.25;
        this.horizontal_shake_multiplier = 0.5;
        this.rot_y_softening = 10;
        this.vertical_recoil_frequency = 3;
        this.lateral_recoil_frequency = 3;
        this.super_recoil_intensity = 5;
        this.sway_frequency = 0.2;
        this.sway_intensity = 0.01;
        this.mouse_delta_base_scale = 0.035;
        this.recoil_lateral_fraction = 0.7;
        this.recoil_lateral_displacement_scale = 0.05;
        this.t_seed_range = 256;
        this.vertical_shake_base_threshold = 1.0;
        this.vertical_shake_frequency_scale = 2.0;
        this.vertical_shake_amplitude_scale = 0.008;

        this.vertical_shake_phase = 0;
        this.last_base_recoil = 0;
        this.blur = blurCreator.createBlur(candidates.Lighting);

        this.min_roll = -(math.pi / 2 - this.roll_limit_buffer);
        this.max_roll = math.pi / 2 - this.roll_limit_buffer;
        this.t = math.random() * this.t_seed_range;
        this.camera_cframe = this.cam_position;
    }

    update(delta_time: number): void {
        const rawDelta = input.get_mouse_delta();
        const scale = this.mouse_delta_base_scale * input.get_mouse_sensitivity();
        this.real_rot_y -= rawDelta.Y * scale;
        this.real_rot_y = math.clamp(this.real_rot_y, this.min_roll, this.max_roll);
        this.real_rot_x -= rawDelta.X * scale;

        this.current_rot_x += (this.real_rot_x - this.current_rot_x) * math.min(1, delta_time * this.look_damping_speed);
        this.current_rot_y += (this.real_rot_y - this.current_rot_y) * math.min(1, delta_time * this.look_damping_speed);

        const head_cframe = this.get_head_cframe();
        this.cam_position = new CFrame(head_cframe.Position);
        let camera_cframe = this.cam_position;

        this.rot_x += (0 - this.rot_x) * math.min(1, delta_time * this.recoil_recovery_speed);
        this.rot_y += (0 - this.rot_y) * math.min(1, delta_time * this.recoil_recovery_speed);

        const base_recoil_addon = this.rot_x + this.rot_y;
        const recoil_rate = (base_recoil_addon - this.last_base_recoil) / delta_time;
        const effective_rate = math.abs(recoil_rate) * this.vertical_shake_base_threshold;

        const shake_recoil = math.sin(base_recoil_addon * math.pi / this.recoil_threshold);
        const shake_recoil_half = math.sin(base_recoil_addon * math.pi / (this.recoil_threshold * this.horizontal_shake_multiplier));
        const total_recoil = shake_recoil * this.recoil_intensity;
        const half_recoil = shake_recoil_half * this.recoil_intensity;
        const softened_rot_y = this.rot_y / (1 + math.abs(this.rot_y) * this.rot_y_softening);

        this.t += delta_time;
        const lateral_recoil = math.noise(this.t * this.lateral_recoil_frequency, 0) * base_recoil_addon * this.super_recoil_intensity * this.recoil_intensity;
        const vertical_recoil = math.noise(this.t * this.vertical_recoil_frequency, 1) * base_recoil_addon * this.super_recoil_intensity * this.recoil_intensity;
        const sway_x = math.noise(this.t * this.sway_frequency, 0) * this.sway_intensity;
        const sway_y = math.noise(this.t * this.sway_frequency, 1) * this.sway_intensity;

        this.vertical_shake_phase += effective_rate * this.vertical_shake_frequency_scale * delta_time;
        const vertical_shake_offset = math.sin(this.vertical_shake_phase * math.pi * 2) * (effective_rate * this.vertical_shake_amplitude_scale);

        const roll_recoil = (1 - this.recoil_lateral_fraction) * total_recoil;
        const lateral_disp_x = math.noise(this.t * this.lateral_recoil_frequency, 2) * base_recoil_addon * this.recoil_lateral_fraction * this.recoil_lateral_displacement_scale;
        const lateral_disp_y = math.noise(this.t * this.vertical_recoil_frequency, 3) * base_recoil_addon * this.recoil_lateral_fraction * this.recoil_lateral_displacement_scale;

        this.blur.Size = math.clamp(base_recoil_addon * this.blur_intensity, this.blur_bound_lower, this.blur_bound_upper);

        camera_cframe = camera_cframe
            .mul(CFrame.Angles(0, this.current_rot_x + lateral_recoil + sway_x, 0))
            .mul(CFrame.Angles((this.current_rot_y - softened_rot_y) + half_recoil * this.horizontal_vis_multiplier + vertical_recoil + sway_y, 0, 0))
            .mul(CFrame.Angles(vertical_shake_offset, 0, 0))
            .mul(CFrame.Angles(0, 0, roll_recoil))
            .mul(CFrame.Angles(0, 0, -(this.roll ?? 0)))
            .mul(new CFrame(lateral_disp_x, lateral_disp_y, 0));

        this.last_base_recoil = base_recoil_addon;
        this.camera_cframe = camera_cframe;
    }
}

register_camera_mode("RecoilCam", CustomFreecam);
}