// thanks from EgoMoose
// https://github.com/EgoMoose/Articles
// saved some time

import { EgoMooseExportDraw3DTriangle, EgoMooseExportGetBarycentricHeight } from "./definition";
// !deadline-ts.customFinishSector_FinishModulesEnd

export namespace EgoMoose {
    export function draw3dTriangle(a: Vector3, b: Vector3, c: Vector3): EgoMooseExportDraw3DTriangle {
        let ab = b.sub(a);
        let ac = c.sub(a);
        let bc = c.sub(b);
        let abd = ab.Dot(ab);
        let acd = ac.Dot(ac);
        let bcd = bc.Dot(bc);
        if (abd > acd && abd > bcd) {
            [c, a] = [a, c];
        } else if(acd > bcd && acd > abd) {
            [a, b] = [b, a];
        }
	    ab = b.sub(a);
        ac = c.sub(a);
        bc = c.sub(b);
        const right = ac.Cross(ab).Unit;
        const up = bc.Cross(right).Unit;
        const back = bc.Unit;
        const height = math.abs(ab.Dot(up));
        return [
            {
                Size: new Vector3(0, height, math.abs(ab.Dot(back))), 
                CFrame: CFrame.fromMatrix((a.add(b)).div(2), right, up, back)
            }, 
            {
                Size: new Vector3(0, height, math.abs(ac.Dot(back))), 
                CFrame: CFrame.fromMatrix((a.add(c)).div(2), right.mul(-1), up, back.mul(-1))
            }
        ];
    }
    
    export function getRandomWeights(): [number, number, number] {
        const r1 = math.random();
        const r2 = math.random();
        const sqrtR1 = math.sqrt(r1);

        const wA = 1 - sqrtR1;
        const wB = sqrtR1 * (1 - r2);
        const wC = r2 * sqrtR1;

        return [wA, wB, wC];
    }

    export function getPointFromWeights(a: Vector2, b: Vector2, c: Vector2, weights: [number, number, number]): Vector2 {
        const [wA, wB, wC] = weights;
        return a.mul(wA).add(b.mul(wB)).add(c.mul(wC));
    }

    export function getBarycentricHeight(vertexA: Vector3, vertexB: Vector3, vertexC: Vector3, samplePoint: Vector2): EgoMooseExportGetBarycentricHeight {
        const projectedDenominator = (vertexB.Z - vertexC.Z) * (vertexA.X - vertexC.X) + (vertexC.X - vertexB.X) * (vertexA.Z - vertexC.Z);
        if (projectedDenominator === 0) return [undefined, 0, 0, 0];

        const weightA = ((vertexB.Z - vertexC.Z) * (samplePoint.X - vertexC.X) + (vertexC.X - vertexB.X) * (samplePoint.Y - vertexC.Z)) / projectedDenominator;
        const weightB = ((vertexC.Z - vertexA.Z) * (samplePoint.X - vertexC.X) + (vertexA.X - vertexC.X) * (samplePoint.Y - vertexC.Z)) / projectedDenominator;
        const weightC = 1 - weightA - weightB;
        const interpolatedHeight = weightA * vertexA.Y + weightB * vertexB.Y + weightC * vertexC.Y;
        return [interpolatedHeight, weightA, weightB, weightC];
    }
}