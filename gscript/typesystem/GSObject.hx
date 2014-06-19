package gscript.typesystem;

import haxe.Json;

class GSObject {
	public var __props__ : NativeMap < String, { v : Dynamic }>;
	public var keyList:Array < GSObject >;
	public var type:String;
	public var value:Dynamic;
	
	public function new() {
		this.__props__ = new NativeMap();
		this.keyList = new Array();
		this.type = 'object';
		this.value = '';
	}
	
//Initialize Ops
	public function initMethods():Void {
		//List of names of methods we're exposing
		var exposedMethods = [
			"__setitem__",
			"__getitem__",
			"__setattr__",
			"__getattr__",
			"__invert__",
			"__add__",
			"__sub__",
			"__mul__",
			"__div__",
			"__mod__",
			"__eq__",
			"__ne__",
			"__lt__",
			"__gt__",
			"__le__",
			"__ge__",
			"__iadd__",
			"__isub__",
			"__imul__",
			"__idiv__",
			"__imod__"
		];
		for ( name in exposedMethods ) {
			var method = Reflect.getProperty( this, name );
			this.exposeMethod( name, method );
		}
	}
	
//Normal Methods
	public function keys():Iterator < GSObject > {
		return this.keyList.iterator();
	}
//Magic Methods	
	
	//Pointer Field Access
	public dynamic function __pget__( key:Dynamic ):Dynamic {
		var pointerGetter = this.__getattr__(new GSString("__pget__"));
		if ( pointerGetter == null ) {
			throw 'TypeError:  Cannot use pointer operator on \'${this.type}\' objects';
		} else {
			return pointerGetter.__invoke__([key]);
		}
	}
	//Pointer Field Assignment
	public dynamic function __pset__( key:Dynamic, value:Dynamic ):Void {
		var pointerSetter = this.__getattr__(new GSString("__pset__"));
		if ( pointerSetter == null ) {
			throw 'TypeError:  Cannot use pointer operator on \'${this.type}\' objects';
		} else {
			pointerSetter.__invoke__([key, value]);
		}
	}
	//Array Write
	public function __setitem__( key:GSObject, value:Dynamic ):Void {
		var realKey:String = key.toString();
		this.__props__.set(realKey, { 'v' : value });
		this.keyList.push(key);
	}
	//Array Read
	public function __getitem__( key:GSObject ):Null<GSObject> {
		var realKey:String = Std.string(key);
		var prop = this.__props__.get( realKey );
		return (prop == null) ? null : prop.v;
	}
	//Dot '.' Write
	public dynamic function __setattr__( key:GSObject, value:GSObject ):Void {
		this.__setitem__( key, value );
	}
	//Dot '.' Read
	public dynamic function __getattr__( key:GSObject ):Null<GSObject> {
		return this.__getitem__( key );
	}
	//Destructor
	public function __delete__():Void {
		var del:GSObject = this.__getattr__(new GSString("__delete__"));
		if ( del == null ) {
			return;
		} else {
			del.__invoke__([]);
		}
	}
	//Array Delete
	public function __deleteitem__( key:GSObject ):Bool {
		var had:Bool = (this.__getitem__(key) != null);
		var realKey:String = Json.stringify(key);
		this.__props__.remove(realKey);
		return had;
	}
	//Dot '.' Delete
	public function __deleteattr__( key:String ):Bool {
		return this.__props__.remove(key);
	}
	//Iteration
	public function __iter__():Iterator < GSObject > {
		return [ for ( entry in this.__props__ ) entry.v ].iterator();
	}
	//Function Invokation
	public function __invoke__( args:Array < GSObject > ):Dynamic {
		var func:Dynamic = this.__getattr__(new GSString("__call__"));
		if ( func == null ) throw 'TypeError: $this cannot be called.';
		var type:String = TypeSystem.basictype(func);
		if ( type == "GSFunction" ) return cast(func, GSFunction).__call__( args );
		else {
			throw 'TypeError: Could not call $func.';
		}
	}
	//Method Invokation
	public function __callmethod__( methodName:GSObject, args:Array < Dynamic > ):Dynamic {
		var key:String = methodName.toString();
		//The 'method' we're referring to is defined by the programmer
		if ( this.__getattr__(methodName) != null ) {
			var method:Dynamic = this.__getattr__(methodName);
			if (TypeSystem.basictype(method) == "GSFunction") {
				method = cast(method, GSFunction);
				return method.__call__(args);
			} else {
				throw 'TypeError: Objects of type ${method.type} are not callable.';
			}
		} else { //The method is an actual method of this object
			throw 'NameError: $this has no method $methodName';
		}
	}
//Type Conversion Magic Methods
	
	//Conversion to GSString
	public function __str__():GSString {
		var repr:Dynamic = {};
		for ( key in this.keys() ) {
			Reflect.setProperty( repr, key.toString(), ((this.__getitem__(key) != null) ? this.__getitem__(key).toString() : null) );
		}
		return new GSString(Json.stringify(repr));
	}
	//Conversion to Boolean
	public function __bool__():Bool {
		return true;
	}
	//Object Inversion
	public function __invert__():Dynamic {
		return this;
	}
	
//Operator Magic Methods
//------------------------

//Binary Mathematical Operators	
	public function __add__( other:GSObject ):Null<GSObject> { // Addition "+"
		var result:GSObject = new GSObject();
		result.__iadd__(this);
		result.__iadd__(other);
		return result;
	}
	public function __sub__( other:GSObject ):Null<GSObject> { //Subtraction "-"
		var result:GSObject = new GSObject();
		result.__iadd__(this);
		result.__isub__(other);
		return result;
	}
	public function __mul__( other:GSObject ):Null<GSObject> { //Multiplication "*"
		return null;
	}
	public function __div__( other:GSObject ):Null<GSObject> {
		return null;
	}
	public function __mod__ ( other:GSObject ):Null<GSObject> {
		return null;
	}
	public function __lshift__( other:GSObject ):Null<GSObject> {
		return null;
	}
	public function __rshift__( other:GSObject ):Null<GSObject> {
		return null;
	}
	public function __and__( other:GSObject ):Null<GSObject> {
		return null;
	}
	public function __or__( other:GSObject ):Null<GSObject> {
		return null;
	}
	public function __land__( other:GSObject ):Null<GSObject> {
		return null;
	}
	public function __lor__( other:GSObject ):Null<GSObject> {
		return null;
	}

//Binary Logical Operators
	public function __eq__( other:GSObject ):Bool {
		return ( this == other );
	}
	public function __ne__( other:GSObject ):Bool {
		return ( this != other );
	}
	public function __lt__( other:GSObject ):Bool {
		return ( this.__props__.keyList.length < other.__props__.keyList.length );
	}
	public function __gt__( other:GSObject ):Bool {
		return ( this.__props__.keyList.length > other.__props__.keyList.length );
	}
	public function __le__( other:GSObject ):Bool {
		return ( this.__props__.keyList.length <= other.__props__.keyList.length );
	}
	public function __ge__( other:GSObject ):Bool {
		return ( this.__props__.keyList.length >= other.__props__.keyList.length );
	}
//Augmented Assignment
	public function __iadd__( other:GSObject ):Void {
		for ( key in other.keys() ) {
			if (this.__getitem__(key) == null) {
				this.__setitem__(key, other.__getitem__(key));
			}
		}
	}
	public function __isub__( other:GSObject ):Void {
		for ( key in other.keys() ) {
			if (this.__getitem__(key) != null) this.__deleteitem__(key);
		}
	}
	public function __imul__( other:GSObject ):Void {
		throw 'TypeError: cannot use "*" operator on objects of type ${this.type}';
	}
	public function __idiv__( other:GSObject ):Void {
		throw 'TypeError: cannot use "/" operator on objects of type ${this.type}';
	}
	public function __imod__( other:GSObject ):Void {
		throw 'TypeError: cannot use "%" operator on objects of type ${this.type}';
	}

//Other Stuff
	public function toString():String {
		return this.__str__().value;
	}
	
	//Function to internally expose a function to GryffinScript
	public function expose( name:String, f:Dynamic ):Void {
		var method = new GSFunction( true, f );
		this.__props__.set(name, {'v':method});
	}
	//Function to internally expose a method to GryffinScript
	public function exposeMethod( name:String, f:Dynamic ):Void {
		var me = this;
		var method = function( data ) {
			return Reflect.callMethod( me, f, data.args );
		};
		this.expose( name, method );
	}
}