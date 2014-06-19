import gscript.Parser;
import gscript.Interp;
import gscript.typesystem.GSObject;
import gscript.typesystem.GSArray;
import gscript.typesystem.GSString;
import gscript.typesystem.GSNumber;
import gscript.typesystem.GSFunction;
import gscript.typesystem.GSPointer;
import gscript.typesystem.GSNativePointer;
import gscript.typesystem.TypeSystem;
import gscript.gsbind.GryffinBind;

class GryffinScript {
	public static function main() {
		var vm = new GryffinScriptRuntime();
		bindBuiltins( vm );
		var args = Sys.args();
		for ( arg in args ) {
			if (sys.FileSystem.exists(arg)) {
				var code:String = sys.io.File.getContent(arg);
				vm.runString(code);
				var main = vm.loadValue("main");
				main();
			}
		}
	}
	public static function bindBuiltins( vm:GryffinScriptRuntime ):Void {
		vm.bindValue("load", function( dlib:Dynamic, dprim:Dynamic, dnargs:Dynamic ) {
			var lib:String = cast(dlib, String);
			var prim:String = cast(dprim, String);
			var nargs:Int = cast(dnargs, Int);
			return cpp.Lib.load( lib, prim, nargs );
		});
		vm.bindValue("print", function( x:Dynamic ):Void {
			cpp.Lib.println(haxe.Json.stringify(x));
		});
	}
}