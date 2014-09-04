package gryffinscript.gscript.gsbind;

import gryffinscript.gscript.typesystem.GSObject;
import gryffinscript.gscript.typesystem.GSArray;
import gryffinscript.gscript.typesystem.GSString;
import gryffinscript.gscript.typesystem.GSNumber;
import gryffinscript.gscript.typesystem.TypeSystem;

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