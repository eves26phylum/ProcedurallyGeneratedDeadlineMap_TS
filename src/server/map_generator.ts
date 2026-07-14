import { EgoMoose                                                                                                                         } from "../shared/EgoMoose"                             ;
import { createTerrain, WedgeCell                                                                                                         } from "../shared/createTerrainFromVerticesUsingAdapter";
import { PerlinNoise                                                                                                                      } from "shared/PerlinNoise"                             ;
import { biomeBox                                                                                                                         } from "shared/biomeAndStructureRegistrySystem"         ;
import { translateTerrainOrientationForStructureBonding                                                                                   } from "shared/translateTerrainForStructureBonding"     ;
import { NuristanBuildings                                                                                                                } from "shared/biomes/NuristanBuildings"                ;
import { isDeadline                                                                                                                       } from "shared/isDeadline"                              ;
import { Logger                                                                                                                           } from "shared/logger"                                  ;
import { Tree                                                                                                                             } from "shared/biomes/Tree"                             ;
import { NuristanStandardBiome                                                                                                            } from "shared/biomes/nuristanStandardBiome"            ;
import { SniperWindowRoomHandler                                                                                                          } from "shared/nuristanHandler/sniperWindow"            ;
import { LivingRoomHandler                                                                                                                } from "shared/nuristanHandler/livingRoom"              ;
import { getWorldRoot                                                                                                                     } from "shared/getRoot"                                 ;
import { adapterToUse                                                                                                                     } from "shared/adapterToUse"                            ;
import { AnyInstance, EgoMooseFiles, InstanceAdapter                                                                                      } from "shared/definition"                              ;
import { assign                                                                                                                           } from "shared/Util"                                    ;
import { NuristanBuildingsConfig, StandardNuristanConfig, TreeConfig, PART_SIZE, PARAMS, RESOLUTION, MAP_SIZE, ROUGHNESS, POSITION_OFFSET } from "./config"                                       ;
export function startMapGenerator() {
    const worldRoot = getWorldRoot();
    const Log = new Logger("map_generator");
    const workspace = worldRoot;
    const offset = new Vector2(math.random(1, 10e6), math.random(1, 10e6));
    const noiseData = new PerlinNoise().generate(PARAMS.scale, RESOLUTION, offset, PARAMS.exaggeratedness, PARAMS.lacunarity, PARAMS.persistence, PARAMS.octaves, PARAMS.power);
    const wedgesFolderToDestroy = adapterToUse.findFirstChild(workspace, "Wedges"); // getservice because we're exporting this to deadline and there's no fucking way am I going to import an entire rbxts node module pipeline
    if (wedgesFolderToDestroy) { adapterToUse.destroy(wedgesFolderToDestroy); }

    const wedgesFolder = adapterToUse.newInstance("Folder");
    adapterToUse.setProperty(wedgesFolder, "Name", "Wedges");
    adapterToUse.setProperty(wedgesFolder, "Parent", workspace);
    const standardBox = new biomeBox();
    const translateTerrain = new translateTerrainOrientationForStructureBonding({
        orientationSubtraction: new Vector3(0, 0, -90) 
    });

    standardBox.registerModifier(new NuristanStandardBiome(adapterToUse, StandardNuristanConfig, wedgesFolder));
    standardBox.registerModifier(new NuristanBuildings(adapterToUse, translateTerrain, NuristanBuildingsConfig, wedgesFolder,
        (thisThing: NuristanBuildings) => {
            return [
                new SniperWindowRoomHandler(thisThing, thisThing.config.sniperWindowDoorway),
                new LivingRoomHandler(thisThing),
            ]
        }
    ));
    standardBox.registerModifier(new Tree(adapterToUse, TreeConfig, wedgesFolder))
    class CustomTriangleFunc {
        private adapter: InstanceAdapter;
        private EgoMoose: EgoMooseFiles;
        private parent: AnyInstance;
        private resolution: Vector2;
        private total: number;
        private count: number;

        constructor(
            adapter: InstanceAdapter,
            EgoMoose: EgoMooseFiles,
            parent: AnyInstance,
            resolution: Vector2
        ) {
            this.adapter = adapter;
            this.EgoMoose = EgoMoose;
            this.parent = parent;
            this.resolution = resolution;
            this.total = this.resolution.X * this.resolution.Y * 2;
            this.count = 0;
        }

        materialise = (thisThing: createTerrain, a: Vector3, b: Vector3, c: Vector3): [AnyInstance<WedgePart>, AnyInstance<WedgePart>] => { // self-less function
            // when given to createTerrain, it calls self:materialiseTriangle (our custom function set in its constructor)
            // then it becomes materialiseTriangle(self, a, b, c)
            // but roblox-ts for some god forsaken reason does not recognise this
            const [AData, BData] = thisThing.EgoMoose.draw3dTriangle(a, b, c);
            const WedgeA = thisThing.adapter.newInstance("WedgePart");
            const WedgeB = thisThing.adapter.newInstance("WedgePart");
            thisThing.adapter.setProperty(WedgeA, "Anchored", true);
            thisThing.adapter.setProperty(WedgeB, "Anchored", true);
            thisThing.adapter.setProperty(WedgeA, "Parent", thisThing.parent);
            thisThing.adapter.setProperty(WedgeB, "Parent", thisThing.parent);
            assign<AnyInstance<WedgePart>>(WedgeA, AData, (item, key, value) => thisThing.adapter.setProperty(item, key, value));
            assign<AnyInstance<WedgePart>>(WedgeB, BData, (item, key, value) => thisThing.adapter.setProperty(item, key, value));
            this.count++;
            if (this.count % 1000 === 0) {
                if (isDeadline) {
                    players.get_all().forEach((player: Player, index: number) => {
                        player.fire_client("biomeLoadingStatus_1", this.count/this.total)
                    });
                }
                task.wait(0.05);
            }
            return [WedgeA, WedgeB];
        }
    }
    let maxHeight = -math.huge;
    function generate() {
        // work on this later
        // prob some bug because it did work earlier on client, but this code does not work or replicate to client from a server
        const newTriangleFunc = new CustomTriangleFunc(adapterToUse, EgoMoose, wedgesFolder, RESOLUTION);
        const total = RESOLUTION.X * RESOLUTION.Y;
        let count = 0;
        const createTerrainDefault = new createTerrain((thisData: WedgeCell) => {
            count++;
            if (count % 250 === 0) {
                if (isDeadline) {
                    players.get_all().forEach((player: Player, index: number) => {
                        player.fire_client("biomeLoadingStatus_2", count/total);
                    });
                }
                task.wait(0.05);
            }
            const _self = thisData._self;
            standardBox.executeAllModifiers(thisData._self, thisData);
            const computedHeight = thisData.data.averageHeightSized * PART_SIZE;
            if (computedHeight > maxHeight) maxHeight = computedHeight;
        }, EgoMoose, adapterToUse, wedgesFolder, newTriangleFunc.materialise);
        return createTerrainDefault.createTrianglesFromData(noiseData, RESOLUTION, PART_SIZE, POSITION_OFFSET);
    }
    Log.log("Generating Afghanistan map.");
    generate();
    Log.info("Done.");
    return maxHeight;
}
