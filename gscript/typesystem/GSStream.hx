package gscript.typesystem;

import gscript.gsbind.GryffinBind;

class GSStream extends GSObject {
	public var readFunction:Dynamic -> Void;
	public var writeFunction:Dynamic -> Void;
	
	public function new( read:Dynamic -> Void, write:Dynamic -> Void ) {
		super();
		this.readFunction = read;
		this.writeFunction = write;
	}
	
	override public function __lshift__( other:GSObject ):Null<GSObject> {
		this.readFunction( other );
		return null;
	}
	
	override public function __rshift__( other:GSObject ):Null<GSObject> {
		this.writeFunction( other );
		return null;
	}
}