package gscript.typesystem;

class GSNumber extends GSObject {
	
	public function new( v:Float ) {
		super();
		this.type = 'number';
		this.value = v;
	}
	
	override public function __getitem__( key:GSObject ):Null<GSObject> {
		return null;
	}
	override public function __setitem__( key:GSObject, value:GSObject ):Void {
		return;
	}
	
//Arithmetic Operators
	override public function __add__( other:GSObject ):Null<GSObject> {
		if (!Reflect.isObject(other)) return null;
		if ( other.type == 'number' ) return new GSNumber( this.value + other.value );
		else if ( other.type == 'string' ) return new GSString( this.value + other.value );
		else {
			trace( other );
			return null;
		};
	}
	override public function __sub__( other:GSObject ):Null<GSObject> {
		if (!Reflect.isObject(other)) return null;
		if ( other.type == 'number' ) return new GSNumber( this.value - other.value );
		else return null;
	}
	override public function __mul__( other:GSObject ):Null<GSObject> {
		if (!Reflect.isObject(other)) return null;
		if ( other.type == 'number' ) return new GSNumber( this.value * other.value );
		else return null;
	}
	override public function __div__( other:GSObject ):Null<GSObject> {
		if (!Reflect.isObject(other)) return null;
		if ( other.type == 'number' ) return new GSNumber( this.value / other.value );
		else return null;
	}
	override public function __mod__( other:GSObject ):Null<GSObject> {
		if (!Reflect.isObject(other)) return null;
		if ( other.type == 'number' ) return new GSNumber( this.value % other.value );
		else return null;
	}
//Augmented Assignment
	override public function __iadd__( other:GSObject ):Void {
		if (!Reflect.isObject(other)) return;
		if ( other.type == 'number' ) this.value += other.value;
	}
	override public function __isub__( other:GSObject ):Void {
		if (!Reflect.isObject(other)) return;
		if ( other.type == 'number' ) this.value -= other.value;
	}
	override public function __imul__( other:GSObject ):Void  {
		if (!Reflect.isObject(other)) return;
		if ( other.type == 'number' ) this.value *= other.value;
	}
	override public function __idiv__( other:GSObject ):Void  {
		if (!Reflect.isObject(other)) return;
		if ( other.type == 'number' ) this.value /= other.value;
	}
	override public function __imod__( other:GSObject ):Void  {
		if (!Reflect.isObject(other)) return;
		if ( other.type == 'number' ) this.value %= other.value;
	}
//Comparison Operators
	override public function __eq__( other:GSObject ):Bool {
		if (!Reflect.isObject(other)) return false;
		if ( other.type != this.type ) return false;
		return ( this.value == other.value );
	}
	override public function __ne__( other:GSObject ):Bool {
		return !(this.__eq__(other));
	}
	
	
//Type Conversion Methods
	override public function __str__():GSString {
		return new GSString( this.value + '' );
	}
	override public function __invert__():Dynamic {
		return (this.value < 0);
	}
}