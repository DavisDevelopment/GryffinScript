package gscript.typesystem;

import haxe.Json;

class GSString extends GSObject {
	
	public function new( str:String ) {
		super();
		if ( TypeSystem.basictype(str) != "String" ) throw 'TypeError: Expected String, got ${TypeSystem.basictype(str)}';
		this.type = 'string';
		this.value = str;
	}

//GryffinScript String Methods

	public function charAt( index:GSNumber ):GSString {
		return new GSString(this.value.charAt(index.value));
	}
	public function charCodeAt( index:GSNumber ):GSNumber {
		return new GSNumber(this.value.charCodeAt(index.value));
	}
	public function indexOf( piece:GSString ):GSNumber {
		return new GSNumber(this.value.indexOf(piece.value));
	}
	
	public function split( piece:GSString ):GSArray {
		var array = [for (x in cast(this.value.split(piece.value), Array<Dynamic>)) new GSString(x)];
		var result = new GSArray();
		for ( x in array ) result.push(x);
		return result;
	}
	
	public function replace( piece:GSString, with:GSString ):GSString {
		var result = StringTools.replace(this.value, piece.toString(), with.toString());
		return new GSString(result);
	}
	
	public function _format( array : Array < GSObject > ):GSString {
		var text:String = this.value;
		for ( i in 0...array.length ) {
			var replO:Null<GSObject> =  array[i];
			if ( replO == null ) replO = new GSString('');
			var repl:String = '';
			if ( replO.toString != null ) repl = replO.toString();
			text = StringTools.replace(text, '{$i}', repl);
		}
		return new GSString(text);
	}
	
	
//Overridden Internal Methods
	override public function __getitem__( key:GSObject ):Null<GSObject> {
		if ( key.type == 'number' ) {
			var index:Int = Math.round(key.value);
			var char:String = this.value.charAt(index);
			return (char == null) ? null : new GSString(char);
		} else {
			var realKey:String = Json.stringify(key);
			if ( realKey == 'length' ) {
				return new GSNumber( this.value.length );
			} else {
				return super.__getitem__( key );
			}
		}
	}
	
	override public function initMethods():Void {
		var me = this;
		var exposedMethods:Array<String> = ['indexOf', 'split', 'replace', 'charAt', 'charCodeAt'];
		for ( name in exposedMethods ) this.exposeMethod(name, Reflect.getProperty(this, name));
		
		//Explicitly Expose the 'format' method
		this.expose('format', function( data ) {
			return me._format( data.args );
		});
	}
	
	override public function __str__():GSString {
		return this;
	}
	
//Operator Methods

// 'Mathematical' Operators
	override public function __add__( other:GSObject ):GSObject {
		if ( other.type == 'string' || other.type == 'number' ) return new GSString( this.value + other.value );
		else {
			var val = other.__str__();
			return this.__add__(val);
		}
	}
	override public function __iadd__( other:GSObject ):Void {
		// If 'other' is a valid GryffinScript type
		if (TypeSystem.basictype(other) != "Null" && TypeSystem.basictype(other) != "Bool" && Reflect.getProperty(other, 'type') != null) {
			if ( other.type == 'string' || other.type == 'number' ) {
				this.value += other.value;
			} else {
				this.value += Std.string(other);
			}
		}
	}
	override public function __div__( other:GSObject ):GSObject {
		if ( other.type == 'string' ) {
			var str = this.value.split( other.value );
			return new GSString( str );
		} else {
			return super.__div__(other);
		}
	}
	override public function __mod__( other:GSObject ):GSObject {
		if ( other.type == 'array' ) {
			var list:Array < GSObject > = [];
			for (x in other.__iter__()) list.push(x);
			return this._format( list );
		} else {
			return null;
		}
	}
// Comparison Operators
	override public function __eq__( other:GSObject ):Bool {
		if ( other.type != this.type ) return false;
		return this.value == other.value;
	}
	override public function __ne__( other:GSObject ):Bool {
		return !(this.__eq__(other));
	}
}