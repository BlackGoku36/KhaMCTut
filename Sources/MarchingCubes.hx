package;

import kha.FastFloat;
import kha.arrays.Float32Array;
import kha.math.FastVector3;

class MarchingCubes {

    var idxV = 0;
    var idxI = 0;
    var surface = 0.5;
    var cube:Array<FastFloat> = [0,0,0,0,0,0,0,0];
    public static var vol:Float32Array;

    var smooth = true;

    public function new() {
        Volume.makeTerrainVolume((volume)->{
            vol = volume;
        });
        generate();
    }

    public function clean() {
        App.mesh.vertices.resize(0);
        App.mesh.indices.resize(0);
        idxI = 0;
        idxV = 0;
    }

    public function generate() {
        for(x in 0...Volume.width-1){
            for(y in 0...Volume.height-1){
                for (z in 0...Volume.width-1){
                    for (i in 0...8){
                        cube[i] = getDensityFromVolume(
                            x + MCData.cornerTable[i].x,
                            y + MCData.cornerTable[i].y,
                            z + MCData.cornerTable[i].z
                        );
                    }
                    polygonize(new FastVector3(x,y,z), cube);
                }
            }
        }
        calculateVertexNormal();
    }

    function polygonize(position:FastVector3, cube:Array<FastFloat>) {

        var configIndex = getConfigIndex(cube);

        if(configIndex == 0 || configIndex == 255) return;

        var edgeIndex = 0;

        for (i in 0...15){
            var indice = MCData.triangleTable[configIndex][edgeIndex];
            if(indice == -1) return;

            var vert1 = position.add(MCData.cornerTable[MCData.edgeIndexes[indice][0]]);
            var vert2 = position.add(MCData.cornerTable[MCData.edgeIndexes[indice][1]]);

            var vertPosition = new FastVector3();

            if(smooth){
                var vert1Sample = cube[MCData.edgeIndexes[indice][0]];
                var vert2Sample = cube[MCData.edgeIndexes[indice][1]];

                var difference = vert2Sample - vert1Sample;

                if (difference == 0) difference = surface;
                else difference = (surface - vert1Sample) / difference;

                vertPosition = vert1.add(vert2.sub(vert1).mult(difference));

            }else {
                vertPosition = vert1.add(vert2).mult(0.5);
            }

            App.mesh.vertices[idxV] = vertPosition.x;
            App.mesh.vertices[idxV+1] = vertPosition.y;
            App.mesh.vertices[idxV+2] = vertPosition.z;
            idxV+=3;

            App.mesh.indices[idxI] = Std.int(App.mesh.vertices.length/3) - 1;
            idxI+=1;

            edgeIndex++;
        }
    }

    inline function getConfigIndex(cube:Array<FastFloat>) {
        var configIndex = 0;

        if(cube[0] > surface) configIndex |= 1;
        if(cube[1] > surface) configIndex |= 2;
        if(cube[2] > surface) configIndex |= 4;
        if(cube[3] > surface) configIndex |= 8;
        if(cube[4] > surface) configIndex |= 16;
        if(cube[5] > surface) configIndex |= 32;
        if(cube[6] > surface) configIndex |= 64;
        if(cube[7] > surface) configIndex |= 128;

        return configIndex;
    }

    inline public function getDensityFromVolume(x:Float, y:Float, z:Float) {
        return vol[Std.int(x) + Std.int(y) * Volume.width + Std.int(z) * Volume.width * Volume.height];
    }

    public static function calculateVertexNormal() {

        var i = 0;
        while (i < App.mesh.indices.length) {
            var indexA = App.mesh.indices[i];
            var indexB = App.mesh.indices[i + 1];
            var indexC = App.mesh.indices[i + 2];

            var vertices = App.mesh.vertices;
            var verticeA = new FastVector3(vertices[indexA*3], vertices[indexA*3+1], vertices[indexA*3+2]);
            var verticeB = new FastVector3(vertices[indexB*3], vertices[indexB*3+1], vertices[indexB*3+2]);
            var verticeC = new FastVector3(vertices[indexC*3], vertices[indexC*3+1], vertices[indexC*3+2]);

            var edgeAB = verticeB.sub(verticeA);
            var edgeAC = verticeC.sub(verticeA);

            var areaWeightedNormal = edgeAB.cross(edgeAC);

            App.mesh.normals[indexA*3] = areaWeightedNormal.x;
            App.mesh.normals[indexA*3+1] = areaWeightedNormal.y;
            App.mesh.normals[indexA*3+2] = areaWeightedNormal.z;
            App.mesh.normals[indexB*3] = areaWeightedNormal.x;
            App.mesh.normals[indexB*3+1] = areaWeightedNormal.y;
            App.mesh.normals[indexB*3+2] = areaWeightedNormal.z;
            App.mesh.normals[indexC*3] = areaWeightedNormal.x;
            App.mesh.normals[indexC*3+1] = areaWeightedNormal.y;
            App.mesh.normals[indexC*3+2] = areaWeightedNormal.z;

            i += 3;
        }
    }
}
