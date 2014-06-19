package gscript.typesystem;

import haxe.Json;

class GSArray extends GSObject {
	public var items:Array < GSObject >;
	
	public function new() {
		super();
		this.type = 'array';
		this.items = new Array();
		this.initMethods();
	}
	//Method Initialization
	override public function initMethods():Void {
		var exposedMethods:Array < String > = [
			"push",
			"pop",
			"join",
			"reverse",
			"slice"
		];
		for ( name in exposedMethods ) {
			this.exposeMethod(name, Reflect.getProperty(this, name));
		}
	}
	
//Getter Methods
	override public function __getitem__( key:GSObject ):Null<GSObject> {
		var realKey:String = key.toString();
		if ( key.type == 'number' ) {
			var index:Int = Math.round(key.value);
			return this.items[index];
		} else {
			var acceptedValues:Array < String > = ['length'];
			if (Lambda.has(acceptedValues, realKey)) {
				switch ( realKey ) {
					case 'length' : return new GSNumber(this.items.length);
					
					default:
						return null;
				}
			} else {
				return super.__getitem__( key );
			}
		}
	}
//Setter Methods
	override public function __setitem__( key:GSObject, value:GSObject ):Void {
		if ( key.type == 'number' ) {
			var index:Int = 0;
			if (TypeSystem.basictype(key.value) == 'Int') index = Math.round(key.value);
			else throw 'IndexError: Array indexes must be integers.';
			this.items[index] = value;
		} else {
			this.__setattr__( key, value );
		}
	}
	
	//Iterator
	override public function __iter__():Iterator < GSObject > {
		return this.items.iterator();
	}
	//Conversion to String
	override public function __str__():GSString {
		var repr:Array < String > = [ for ( item in this.items ) Std.string(item) ];
		return new GSString(Json.stringify(repr));
	}
	
//GryffinScript Array Methods
	public function push ( item:GSObject ):Void {
		this.items.push( item );
	}
	public function pop():Null<GSObject> {
		return this.items.pop();
	}
	public function join( joiner:GSString ):GSString {
		var sep:String = cast( joiner.value, String );
		var string:String = this.items.join(sep);
		return new GSString(string);
	}
	public function reverse():GSArray {
		var copy:Array < GSObject > = this.items.copy();
		copy.reverse();
		return GSArray.fromArray(copy);
	}
	public function slice( si:Int, ?ei:Int ):GSArray {
		return GSArray.fromArray(this.items.slice(si, ei));
	}

//Operator Methods
	override public function __mul__( other:GSObject ) {
		if ( other.type == 'number' ) {
			var multiplied = this.items.copy();
			for ( x in 0...other.value ) multiplied = multiplied.concat(this.items.copy());
			var result = new GSArray();
			for ( x in multiplied ) result.push(x);
			return result;
		} else {
			return null;
		}
	}
	
//Static Class Methods
	public static function fromArray( list:Array < GSObject > ):GSArray {
		var result:GSArray = new GSArray();
		for ( item in list ) result.push(item);
		return result;
	}
}