import { InstanceAdapter, AnyInstance } from "./definition";
// !deadline-ts.customFinishSector_FinishModulesEnd

const INTERIOR_DIMENSION = 9;
const WALL_THICKNESS = 3;
const EXTERIOR_DIMENSION = INTERIOR_DIMENSION + WALL_THICKNESS * 2;
const INTERIOR_HALF_DIMENSION = INTERIOR_DIMENSION / 2;
const WALL_CENTER_OFFSET = INTERIOR_HALF_DIMENSION + WALL_THICKNESS / 2;

const GLASS_TRANSPARENCY = 0.3;
const GLASS_COLOR = Color3.fromRGB(200, 230, 255);

const SIGN_WIDTH = 4;
const SIGN_HEIGHT = 2;
const SIGN_DEPTH = 0.2;
const SIGN_TEXT_SIZE = 16;
const SIGN_PIXELS_PER_STUD = 50;
const SIGN_TEXT_COLOR = new Color3(1, 1, 1);
const SIGN_SURFACE_COLOR = Color3.fromRGB(102, 102, 110);

const LIGHT_FIXTURE_SIZE = new Vector3(1, 0.5, 1);
const LIGHT_FIXTURE_COLOR = Color3.fromRGB(255, 255, 200);
const LIGHT_BRIGHTNESS = 1;
const LIGHT_RANGE = 16;
const LIGHT_COLOR = Color3.fromRGB(255, 255, 200);
// todo make this a config but whatever it's a preset prefab

export class SpectatorBox {
    private readonly adapter: InstanceAdapter;
    private readonly boxModel: AnyInstance<Folder>;
    private readonly signTextDisplayLabel: AnyInstance<TextLabel>;
    centerBoxPosition: Vector3

    constructor(adapter: InstanceAdapter, centerBoxPosition: Vector3, parent?: AnyInstance) {
        this.adapter = adapter;
        this.boxModel = adapter.newInstance("Folder", parent);
        adapter.setProperty(this.boxModel, "Name", "SpectatorBox");
        this.centerBoxPosition = centerBoxPosition;
        this.buildGlassEnclosure(centerBoxPosition);
        this.signTextDisplayLabel = this.buildInteriorSign(centerBoxPosition.add(new Vector3(0, (WALL_CENTER_OFFSET - WALL_THICKNESS / 2) - SIGN_HEIGHT / 2, 0)));
        this.buildCeilingLightFixture(centerBoxPosition);
    }

    public setSignText(text: string): void {
        this.adapter.setProperty(this.signTextDisplayLabel, "Text", text);
    }

    public destroy(): void {
        this.adapter.destroy(this.boxModel);
    }

    private buildGlassEnclosure(center: Vector3): void {
        this.createGlassWall(
            new Vector3(EXTERIOR_DIMENSION, WALL_THICKNESS, EXTERIOR_DIMENSION),
            center.add(new Vector3(0, -WALL_CENTER_OFFSET, 0)),
            "Floor"
        );
        this.createGlassWall(
            new Vector3(EXTERIOR_DIMENSION, WALL_THICKNESS, EXTERIOR_DIMENSION),
            center.add(new Vector3(0, WALL_CENTER_OFFSET, 0)),
            "Ceiling"
        );
        this.createGlassWall(
            new Vector3(EXTERIOR_DIMENSION, INTERIOR_DIMENSION, WALL_THICKNESS),
            center.add(new Vector3(0, 0, WALL_CENTER_OFFSET)),
            "FrontWall"
        );
        this.createGlassWall(
            new Vector3(EXTERIOR_DIMENSION, INTERIOR_DIMENSION, WALL_THICKNESS),
            center.add(new Vector3(0, 0, -WALL_CENTER_OFFSET)),
            "BackWall"
        );
        this.createGlassWall(
            new Vector3(WALL_THICKNESS, INTERIOR_DIMENSION, EXTERIOR_DIMENSION),
            center.add(new Vector3(-WALL_CENTER_OFFSET, 0, 0)),
            "LeftWall"
        );
        this.createGlassWall(
            new Vector3(WALL_THICKNESS, INTERIOR_DIMENSION, EXTERIOR_DIMENSION),
            center.add(new Vector3(WALL_CENTER_OFFSET, 0, 0)),
            "RightWall"
        );
    }

    private buildInteriorSign(center: Vector3): AnyInstance<TextLabel> {
        const interiorSignPart = this.adapter.newInstance("Part", this.boxModel);
        this.adapter.setProperty(interiorSignPart, "Name", "InteriorSign");
        this.adapter.setProperty(interiorSignPart, "Size", new Vector3(SIGN_WIDTH, SIGN_HEIGHT, SIGN_DEPTH));
        this.adapter.setProperty(interiorSignPart, "CFrame", new CFrame(
            center.X,
            center.Y,
            center.Z - INTERIOR_HALF_DIMENSION + SIGN_DEPTH / 2
        ));
        this.adapter.setProperty(interiorSignPart, "Material", Enum.Material.Metal);
        this.adapter.setProperty(interiorSignPart, "Color", SIGN_SURFACE_COLOR);
        this.adapter.setProperty(interiorSignPart, "Anchored", true);

        const signSurfaceGui = this.adapter.newInstance("SurfaceGui", interiorSignPart);
        this.adapter.setProperty(signSurfaceGui, "Face", Enum.NormalId.Back);
        this.adapter.setProperty(signSurfaceGui, "SizingMode", Enum.SurfaceGuiSizingMode.PixelsPerStud);
        this.adapter.setProperty(signSurfaceGui, "PixelsPerStud", SIGN_PIXELS_PER_STUD);

        const signTextDisplayLabel = this.adapter.newInstance("TextLabel", signSurfaceGui);
        this.adapter.setProperty(signTextDisplayLabel, "Size", new UDim2(1, -8, 1, -8));
        this.adapter.setProperty(signTextDisplayLabel, "Position", new UDim2(0, 4, 0, 4));
        this.adapter.setProperty(signTextDisplayLabel, "TextSize", SIGN_TEXT_SIZE);
        this.adapter.setProperty(signTextDisplayLabel, "TextWrapped", true);
        this.adapter.setProperty(signTextDisplayLabel, "RichText", false);
        this.adapter.setProperty(signTextDisplayLabel, "Font", Enum.Font.Gotham);
        this.adapter.setProperty(signTextDisplayLabel, "TextColor3", SIGN_TEXT_COLOR);
        this.adapter.setProperty(signTextDisplayLabel, "BackgroundTransparency", 1);
        this.adapter.setProperty(signTextDisplayLabel, "TextYAlignment", Enum.TextYAlignment.Top);
        this.adapter.setProperty(signTextDisplayLabel, "TextXAlignment", Enum.TextXAlignment.Left);
        this.adapter.setProperty(signTextDisplayLabel, "Text", "");

        return signTextDisplayLabel;
    }

    private buildCeilingLightFixture(center: Vector3): void {
        const ceilingLightFixturePart = this.adapter.newInstance("Part", this.boxModel);
        this.adapter.setProperty(ceilingLightFixturePart, "Name", "CeilingLightFixture");
        this.adapter.setProperty(ceilingLightFixturePart, "Size", LIGHT_FIXTURE_SIZE);
        this.adapter.setProperty(ceilingLightFixturePart, "CFrame", new CFrame(
            center.X,
            center.Y + INTERIOR_HALF_DIMENSION - LIGHT_FIXTURE_SIZE.Y / 2,
            center.Z
        ));
        this.adapter.setProperty(ceilingLightFixturePart, "Material", Enum.Material.Neon);
        this.adapter.setProperty(ceilingLightFixturePart, "Color", LIGHT_FIXTURE_COLOR);
        this.adapter.setProperty(ceilingLightFixturePart, "Anchored", true);
        this.adapter.setProperty(ceilingLightFixturePart, "CastShadow", false);

        const ceilingPointLight = this.adapter.newInstance("PointLight", ceilingLightFixturePart);
        this.adapter.setProperty(ceilingPointLight, "Brightness", LIGHT_BRIGHTNESS);
        this.adapter.setProperty(ceilingPointLight, "Range", LIGHT_RANGE);
        this.adapter.setProperty(ceilingPointLight, "Color", LIGHT_COLOR);
        this.adapter.setProperty(ceilingPointLight, "Enabled", true);
    }

    private createGlassWall(wallSize: Vector3, wallCenterPosition: Vector3, wallPartName: string): AnyInstance<Part> {
        const glassWallPart = this.adapter.newInstance("Part", this.boxModel);
        this.adapter.setProperty(glassWallPart, "Name", wallPartName);
        this.adapter.setProperty(glassWallPart, "Size", wallSize);
        this.adapter.setProperty(glassWallPart, "CFrame", new CFrame(wallCenterPosition));
        this.adapter.setProperty(glassWallPart, "Material", Enum.Material.Glass);
        this.adapter.setProperty(glassWallPart, "Transparency", GLASS_TRANSPARENCY);
        this.adapter.setProperty(glassWallPart, "Color", GLASS_COLOR);
        this.adapter.setProperty(glassWallPart, "Anchored", true);
        this.adapter.setProperty(glassWallPart, "CastShadow", false);
        this.adapter.addTag(glassWallPart, "glass_invincible");
        return glassWallPart;
    }
}