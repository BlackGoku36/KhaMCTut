package;

import kha.Scheduler;
import kha.Framebuffer;

class App {

	public static var mesh:Mesh;
	public static var mc:MarchingCubes;

	var deltaTime:Float = 0.0;
	var totalFrames:Int = 0;
	var elapsedTime:Float = 0.0;
	var previousTime:Float = 0.0;
	var fps:Int = 0;

	static var onEndFrames: Array<Void->Void> = [];

	var kb = Input.getKeyboard();

	public function new() {
		mesh = new Mesh();
		mc = new MarchingCubes();
		mesh.load();
	}

	public function update() {
		mesh.update();

		if(kb.started(Up)){
			mc.configIndex +=1;
			mc.clean();
			mc.generate();
			App.mesh.remesh();
		}

		if (onEndFrames != null) for (endFrames in onEndFrames) endFrames();
	}

	public function render(g:Framebuffer) {
		var currentTime:Float = Scheduler.realTime();
		deltaTime = (currentTime - previousTime);

		elapsedTime += deltaTime;
		if (elapsedTime >= 1.0) {
			fps = totalFrames;
			totalFrames = 0;
			elapsedTime = 0;
		}
		totalFrames++;

		mesh.render(g.g4);

		trace('FPS: $fps');
		previousTime = currentTime;
	}


	public static function notifyOnEndFrame(func:Void->Void) {
		if (onEndFrames == null) onEndFrames = [];
		onEndFrames.push(func);
	}

}
