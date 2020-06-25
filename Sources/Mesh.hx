package;

import kha.arrays.Uint32Array;
import kha.arrays.Int16Array;
import kha.graphics4.Graphics;
import kha.FastFloat;
import kha.Shaders;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.Usage;
import kha.graphics4.ConstantLocation;
import kha.graphics4.CompareMode;
import kha.graphics4.CullMode;
import kha.math.FastVector3;

class Mesh {

	static var vertexBuffer:VertexBuffer;
	static var indexBuffer:IndexBuffer;
	static var structure: VertexStructure;
	var structureLength = 0;

	var pipeline:PipelineState;

	var mvpID:ConstantLocation;
	var modelMatrixID:ConstantLocation;

	var lightPositionC:ConstantLocation;
	var lightColorC:ConstantLocation;

	var objectAlbedoC:ConstantLocation;
	var objectAmbientOcclusionC:ConstantLocation;

	public var vertices:Array<Float> = [];
	public var indices:Array<Int> = [];
	public var normals:Array<Float> = [];

	public var lightPosition: FastVector3 = new FastVector3(1.0, 17.7, 1.0);

	public var objectAlbedo: FastVector3 = new FastVector3(1.0, 0.5, 0.3);
	public var objectAmbientOcclusion: FastFloat = 0.2;

	public var lightColor = new FastVector3(1, 1, 1);

	public var cameraContoller: CameraController;

	public function new() {
		cameraContoller = new CameraController();
	}

	public function load() {

		structure = new VertexStructure();
		structure.add("pos", VertexData.Short4Norm);
		structure.add("nor", VertexData.Short2Norm);
		structureLength = Std.int(structure.byteSize()/4);

		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.fragmentShader = Shaders.shade_frag;
		pipeline.vertexShader = Shaders.shade_vert;

		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;

		pipeline.cullMode = CullMode.None;
		pipeline.compile();

		mvpID = pipeline.getConstantLocation("MVP");
		modelMatrixID = pipeline.getConstantLocation("M");

		objectAlbedoC = pipeline.getConstantLocation("objectAlbedo");
		objectAmbientOcclusionC = pipeline.getConstantLocation("objectAO");

		lightPositionC = pipeline.getConstantLocation("lightPosition");
		lightColorC = pipeline.getConstantLocation("lightColor");

		for(i in 0...vertices.length){
			vertices[i] = vertices[i] * (1 / 32);
		}

		var convert = convert();
		vertexBuffer = new VertexBuffer(Std.int(convert.verts.length / 4), structure, Usage.StaticUsage);
		var vbData = vertexBuffer.lockInt16();
		for (i in 0...Std.int(vbData.length / structureLength)) {
			vbData.set(i * structureLength, convert.verts[i * 4]);
			vbData.set(i * structureLength + 1, convert.verts[i * 4 + 1]);
			vbData.set(i * structureLength + 2, convert.verts[i * 4 + 2]);
			vbData.set(i * structureLength + 3, convert.verts[i * 4 + 3]);
			vbData.set(i * structureLength + 4, convert.nor[i * 2]);
			vbData.set(i * structureLength + 5, convert.nor[i * 2+ 1]);
		}
		vertexBuffer.unlock();

		indexBuffer = new IndexBuffer(convert.ind.length, Usage.StaticUsage);

		var iData = indexBuffer.lock();
		for (i in 0...iData.length) {
			iData[i] = convert.ind[i];
		}
		indexBuffer.unlock();
	}

	public function remesh() {

		var vbData = vertexBuffer.lock();
		for (i in 0...Std.int(vbData.length / structureLength)) {
			vbData.set(i * structureLength, vertices[i * 3]);
			vbData.set(i * structureLength + 1, vertices[i * 3 + 1]);
			vbData.set(i * structureLength + 2, vertices[i * 3 + 2]);
			vbData.set(i * structureLength + 3, normals[i * 3]);
			vbData.set(i * structureLength + 4, normals[i * 3 + 1]);
			vbData.set(i * structureLength + 5, normals[i * 3 + 2]);
		}
		vertexBuffer.unlock();

		var iData = indexBuffer.lock();
		for (i in 0...iData.length) {
			iData[i] = indices[i];
		}
		indexBuffer.unlock();
	}

	public function update() {
		cameraContoller.update();
	}

	public function render(g:Graphics) {
		g.begin();
		g.clear(kha.Color.fromFloats(0.7, 0.7, 0.7));
		g.setPipeline(pipeline);
		g.setVertexBuffer(vertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setMatrix(mvpID, cameraContoller.mvp);
		g.setMatrix(modelMatrixID, cameraContoller.model);
		g.setVector3(objectAlbedoC, objectAlbedo);
		g.setFloat(objectAmbientOcclusionC, objectAmbientOcclusion);
		g.setVector3(lightPositionC, lightPosition);
		g.setVector3(lightColorC, lightColor);
		g.drawIndexedVertices();
		g.end();
	}

	function convert() {
		var numVertices = Std.int(vertices.length / 3);
		var posI16 = new Int16Array(numVertices * 4); // pos.xyz, nor.z
		var norI16 = new Int16Array(numVertices * 2); // nor.xy
		toI16(posI16, norI16, vertices, normals);

		var indU32 = new Uint32Array(indices.length);
		toU32(indU32, indices);

		return{verts:posI16, nor:norI16, ind:indU32}
	}

	function toI16(toPos:Int16Array, toNor:Int16Array, fromPos:Array<Float>, fromNor:Array<Float>) {
		var numVertices = Std.int(fromPos.length / 3);
		for (i in 0...numVertices) {
			// Values are scaled to the signed short (-32768, 32767) range
			// In the shader, vertex data is normalized into (-1, 1) range
			toPos[i * 4    ] = Std.int(fromPos[i * 3    ] * 32767);
			toPos[i * 4 + 1] = Std.int(fromPos[i * 3 + 1] * 32767);
			toPos[i * 4 + 2] = Std.int(fromPos[i * 3 + 2] * 32767);
			toNor[i * 2    ] = Std.int(fromNor[i * 3    ] * 32767);
			toNor[i * 2 + 1] = Std.int(fromNor[i * 3 + 1] * 32767);
			// normal.z component is packed into position.w component
			toPos[i * 4 + 3] = Std.int(fromNor[i * 3 + 2] * 32767);
		}
	}

	function toU32(to:Uint32Array, from:Array<Int>) {
		for (i in 0...to.length) to[i] = from[i];
	}
}
