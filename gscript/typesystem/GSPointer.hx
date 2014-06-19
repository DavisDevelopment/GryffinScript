package gscript.typesystem;

class GSPointer extends GSObject {
	public var interp:Interp;
	public var address:Dynamic;
	
	public function new( to:Dynamic, scope:Interp ) {
		super();
		this.type = 'pointer';
		this.address = to;
		this.interp = scope;
		if (TypeSystem.basictype(to) == "GSPointer") this.address = to.address;
	}
	
//Pointer Field Access
	override public function __pget__( key:Dynamic ):Dynamic {
		var type:String = TypeSystem.basictype(key);
		trace(key);
		if ( key.type == 'string' ) return this.address.__getattr__(key);
		else if ( key.type == 'number' ) return this.address.__getitem__(key);
		else if ( key.type == 'pointer' ) return this.__pget__(key.address);
		else return super.__pget__(key);
	}
//Pointer Field Assignment
	override public function __pset__( key:Dynamic, value:Dynamic ):Void {
		if ( key.type == 'string' || key.type == 'number' ) {
			if ( key.type == 'string' ) this.address.__setattr__( key, value );
			if ( key.type == 'number' ) this.address.__setitem__( key, value );
		} else {
			throw 'TypeError: Pointer assignment field can only be strings or numbers';
		}
	}
//Pointer Address Reassignment
	public function __reassign__( value:Dynamic ):Void {
		var references = this.getReferences();
		for ( reference in references ) {
			var mem = this.interp.locals.get(reference);
			if ( mem != null ) {
				mem.r = value;
			} else {
				this.interp.variables.set(reference, value);
			}
		}
		this.address.__delete__();
		this.address = value;
	}
	
//Destructor
	override public function __delete__():Void {
		this.address.__delete__();
		for (reference in this.getReferences()) {
			var wasLocal:Bool = this.interp.locals.remove(reference);
			if (!wasLocal) this.interp.variables.remove(reference);
		}
	}
	
	override public function toString():String {
		return 'Pointer -> ${this.address}';
	}
	public function getReferences():Array < String > {
		var references:Array < String > = [];
		for ( k in this.interp.locals.keys() ) {
			var obj = this.interp.locals.get(k).r;
			if ( obj == this.address ) references.push(k);
		}
		if ( true ) {
			for ( k in this.interp.variables.keys() ) {
				var obj = this.interp.variables.get(k);
				if ( obj == this.address ) {
					references.push(k);
				}
			}
		}
		return references;
	}
}