
import gscript.Parser;
import gscript.Interp;
import gscript.FileSystem;
import gscript.typesystem.GSObject;
import gscript.typesystem.GSArray;
import gscript.typesystem.GSString;
import gscript.typesystem.GSStream;
import gscript.typesystem.GSNumber;
import gscript.typesystem.GSFunction;
import gscript.typesystem.GSNativePointer;
import gscript.typesystem.TypeSystem;
import gscript.gsbind.GryffinBind;
import haxe.Unserializer;

class GryffinScriptRuntime {
	public var parser:Parser;
	public var interp:Interp;
	
	public function new() {
		this.parser = new Parser();
		this.parser.allowJSON = true;
		this.interp = new Interp();
	}
	public function getModule( path:String ):GSObject {
		var code:String = "";
		if (FileSystem.exists(path+'.gryf')) {
			code = FileSystem.getString(path+'.gryf');
		} else {
			throw 'Error: could not load module $path';
		}
		var vm = new GryffinScriptRuntime();
		vm.bindBuiltins();
		vm.runString(code);
		return vm.interp.variables.get("exports");
	}
	public function bindBuiltins():Void {
		var me = this;
		var interp = this.interp;
		interp.variables.set("exports", new GSObject());
		var gsrequire = new GSFunction(true, function( data ) {
			var modulePath:String = Std.string(data.args[0]);
			return me.getModule(modulePath);
		});
		interp.variables.set("require", gsrequire);
		var range = new GSFunction(true, function( data ) {
			var firstArg = data.args[0];
			var secondArg = data.args[1];
			if ( firstArg.type == 'number' && secondArg.type == 'number' ) {
				var start:Int = Math.round(firstArg.value);
				var end:Int = Math.round(secondArg.value);
				var holder:GSArray = new GSArray();
				for ( x in start...end ) holder.push(new GSNumber(x));
				return holder;
			} else {
				throw 'TypeError: \'range\' take two arguments, both of which are numbers, you supplied [${firstArg.type}, ${secondArg.type}]';
				return null;
			}
		});
		interp.variables.set("range", range);
		var callable = new GSFunction(true, function(data) {
			var thing = data.args[0];
			return interp.callable(thing);
		});
		interp.variables.set("callable", callable);
		var type = new GSFunction(true, function(data) {
			var thing:Dynamic = data.args[0];
			var type:String = 'unknown';
			if ( thing == null ) type = 'undefined';
			if (Reflect.getProperty(thing, 'type') != null) type = Reflect.getProperty(thing, 'type');
			return new GSString(type);
		});
		interp.variables.set("type", type);
	}
	public function runString( code:String ):Dynamic {
		var program = this.parser.parseString(code);
		this.bindBuiltins();
		return this.interp.execute(program);
	}
	public function loadValue( key:String ):Dynamic {
		return GryffinBind.toNative(this.interp.variables.get(key));
	}
	public function bindValue( key:String, value:Dynamic ):Void {
		var gsValue = GryffinBind.fromNative(value);
		this.interp.variables.set(key, gsValue);
	}
	public function bindValueAsPointer( key:String, value:Dynamic ):GSNativePointer {
		var ptr:GSNativePointer = new GSNativePointer( value, this.interp );
		this.interp.variables.set(key, ptr);
		return ptr;
	}
	public function bindClass( key:String, value:Dynamic ):Void {
		var gsClass = GryffinBind.bindClass(value);
		this.interp.variables.set(key, gsClass);
	}
}