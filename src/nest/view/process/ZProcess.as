package nest.view.process 
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import nest.control.EngineBase;
	import nest.object.IMesh;
	import nest.object.Sprite3D;
	import nest.view.Shader3D;
	
	/**
	 * ZProcess
	 * <p>Decode:</p>
	 * <p>dp4, dest, color, fc</p>
	 * <p>fc: 1 / (256 * 256 * 256), 1 / (256 * 256), 1 / 256, 1</p>
	 */
	public class ZProcess implements IProcess {
		
		private var draw:Matrix3D;
		private var shader:Shader3D;
		
		private var data:Vector.<Number>;
		
		public function ZProcess() {
			draw = new Matrix3D();
			shader = new Shader3D();
			shader.setFromString("m44 op, va0, vc0\nmov v0, va1" , 
								"mov ft0, v0.z\n" + 
								"mul ft1, fc0, ft0\n" + 
								"frc ft1, ft1\n" + 
								"mul ft2, ft1.xxyz, fc1\n" + 
								"sub oc, ft1, ft2\n", 
								false);
			data = Vector.<Number>([256 * 256 * 256, 256 * 256, 256, 1, 0, 1 / 256, 1 / 256, 1 / 256]);
		}
		
		public function doMesh(mesh:IMesh):void {
			var context3d:Context3D = EngineBase.context3d;
			
			draw.copyFrom(mesh.worldMatrix);
			draw.append(EngineBase.camera.invertMatrix);
			if (mesh is Sprite3D) {
				var comps:Vector.<Vector3D> = draw.decompose();
				comps[1].setTo(0, 0, 0);
				draw.recompose(comps);
			}
			draw.append(EngineBase.camera.pm);
			
			context3d.setCulling(mesh.culling);
			context3d.setBlendFactors(mesh.blendMode.source, mesh.blendMode.dest);
			context3d.setDepthTest(mesh.blendMode.depthMask, Context3DCompareMode.LESS);
			context3d.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, draw, true);
			context3d.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, data, 2);
			
			mesh.data.upload(context3d, true, false);
			
			context3d.setProgram(shader.program);
			context3d.drawTriangles(mesh.data.indexBuffer);
			
			mesh.data.unload(context3d);
		}
		
	}

}