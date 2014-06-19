package gscript.gsbind;

import gscript.typesystem.GSObject;
import gscript.typesystem.GSArray;
import gscript.typesystem.GSString;
import gscript.typesystem.GSNumber;
import gscript.typesystem.TypeSystem;

class BoundClass extends BoundObject {
	public function new( obj:Dynamic ) {
		super(obj);
	}
	override public function initMethods():Void {
		var me = this;
		this.expose("__create__", function( data ) {
			return me.__create__( data.args );
		});
	}
	public function __create__( args:Array < GSObject > ):GSObject {
		var list = GSArray.fromArray(args);
		var nativeArgs = GryffinBind.toNative(list);
		trace(nativeArgs);
		var instance = Type.createInstance(this.target, nativeArgs);
		trace(instance);
		return GryffinBind.fromNative(instance);
	}
}