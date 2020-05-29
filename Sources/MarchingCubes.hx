package;

import kha.math.FastVector3;

class MarchingCubes {

    public var configIndex = 1;
    var idxV = 0;
    var idxI = 0;

    public function new() {
        generate();
    }

    public function clean() {
        App.mesh.vertices.resize(0);
        App.mesh.indices.resize(0);
        idxI = 0;
        idxV = 0;
    }

    public function generate() {
        polygonize(new FastVector3(0, 0, 50));
        calculateVertexNormal();
    }

    function polygonize(position:FastVector3) {

        if(configIndex == 0 || configIndex == 255) return;

        var edgeIndex = 0;

        for (i in 0...15){
            var indice = MCData.triangleTable[configIndex][edgeIndex];
            if(indice == -1) return;

            var vert1 = position.add(MCData.cornerTable[MCData.edgeIndexes[indice][0]]);
            var vert2 = position.add(MCData.cornerTable[MCData.edgeIndexes[indice][1]]);

            var vertPosition = vert1.add(vert2).mult(0.5);

            App.mesh.vertices[idxV] = vertPosition.x;
            App.mesh.vertices[idxV+1] = vertPosition.y;
            App.mesh.vertices[idxV+2] = vertPosition.z;
            idxV+=3;

            App.mesh.indices[idxI] = Std.int(App.mesh.vertices.length/3) - 1;
            idxI+=1;

            edgeIndex++;
        }
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
