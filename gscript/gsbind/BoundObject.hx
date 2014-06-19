package gscript.gsbind;

import gscript.typesystem.GSObject;
import gscript.typesystem.GSArray;
import gscript.typesystem.GSString;
import gscript.typesystem.GSNumber;
import gscript.typesystem.TypeSystem;

class BoundObject extends GSObject {
	public var target:Dynamic;
	
	public function new( obj:Dynamic ) {
		super();
		this.target = obj;
		this.type = 'object';
		this.initMethods();
	}
//Getter/Setter Methods
	override public function __getattr__( k:GSObject ):GSObject {
		var key:String = Std.string(k);
		var prop:Dynamic = Reflect.getProperty(this.target, key);
		if ( prop != null ) {
			return GryffinBind.fromNative(prop);
		} else {
			return super.__getattr__(k);
		}
	}
	override public function __setattr__( k:GSObject, v:GSObject ):Void {
		var key:String = Std.string(k);
		var value:Dynamic = GryffinBind.toNative(v);
		Reflect.setProperty( this.target, key, value );
	}
}