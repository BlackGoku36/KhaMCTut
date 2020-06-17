package;

import kha.arrays.Float32Array;

class Volume {

    public static var width = 32;
    public static var height = 32;
    public static var offset = 1.5;

    public static function makeTerrainVolume(done:(Float32Array)->Void) {

        var volume = new Float32Array(width * height * width);
        var perlin = new Perlin();

        for (x in 0...width){
            for(z in 0...width){
                for (y in 0...height){

                    var density = 10 * perlin.perlin(x/ 16 + offset, y/ 16 + offset, z/ 16 + offset);
                    var l = (x) + (y * width) + (z * height * width);
                    volume[l] = y-density;
                }
            }
        }
        done(volume);
    }
}
