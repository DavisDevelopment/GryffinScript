import gryffinscript.gscript.Parser;
import gryffinscript.gscript.Interp;
import gryffinscript.gscript.typesystem.GSObject;
import gryffinscript.gscript.typesystem.GSArray;
import gryffinscript.gscript.typesystem.GSString;
import gryffinscript.gscript.typesystem.GSNumber;
import gryffinscript.gscript.typesystem.GSFunction;
import gryffinscript.gscript.typesystem.GSPointer;
import gryffinscript.gscript.typesystem.GSNativePointer;
import gryffinscript.gscript.typesystem.TypeSystem;
import gryffinscript.gscript.gsbind.GryffinBind;

class gryffinscript.gscript {
	public static function main() {
		var vm = new gryffinscript.gscriptRuntime();
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
	public static function bindBuiltins( vm:gryffinscript.gscriptRuntime ):Void {
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