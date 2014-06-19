package gscript.typesystem;

import haxe.Serializer;
import haxe.Unserializer;

class GSFunction extends GSObject {
	public var environment:Interp;
	public var __prototype__:GSObject;
	public var name:Null<GSString>;
	public var body:Expr;
	public var parameters:Array < Dynamic >;
	public var native:Bool;
	public var func:Dynamic;
	public var defaultThisValue:Null<GSObject>;
	public var scope:Map<String, { r : Dynamic }>;
	
	public function new ( native:Bool, value:Dynamic, ?body, ?params:Array<Dynamic>, ?env:Interp, ?scope ) {
		super(); 
		
		this.native = native;
		if ( this.native ) {
			this.func = value;
		} else {
			if ( body == null || params == null || env == null || scope == null ) throw 'TypeError: Cannot initialize function without a link to the interpreter.';
			this.name = (value != null) ? cast( value, GSString ) : null;
			this.body = body;
			this.parameters = params;
			this.environment = env;
			this.scope = scope;
		}
		this.defaultThisValue = null;
		this.type = 'function';
		this.__prototype__ = new GSObject();
	}
	public function __call__( args:Array < GSObject >, ?thisValue:GSObject ) {
		var myArgs = args.copy();
		var self:Null<GSObject> = this.defaultThisValue;
		if ( thisValue != null ) self = thisValue;
		if ( !this.native ) {
			var params = this.parameters;
			var me = this.environment;
			var old = me.locals;
			me.locals = me.duplicate(this.scope);
			var argumentVariable:GSArray = new GSArray();
			for ( arg in args ) argumentVariable.push(arg);
			me.locals.set('arguments', {'r':argumentVariable});
			me.locals.set('this', {'r': self});
			for( i in 0...this.parameters.length )
				me.locals.set(params[i].name,{ r : args[i] });
			var r = null;
			try {
				r = me.exprReturn(this.body);
			} catch( e : Dynamic ) {
				me.locals = old;
				#if neko
				neko.Lib.rethrow(e);
				#else
				throw e;
				#end
			}
			me.locals = old;
			return r;
		} else {
			var invokationData:Dynamic = {
				'self' : self,
				'args' : myArgs
			};
			return Reflect.callMethod( null, this.func, [invokationData] );
		}
	}
	public function dump():GSString {
		var data:Dynamic = {
			'body' : this.body,
			'params' : this.parameters,
			'scope' : this.scope,
			'thisValue' : this.defaultThisValue
		};
		var serializer = new Serializer();
		serializer.useEnumIndex = true;
		serializer.useCache = true;
		serializer.serialize( data );
		var string:String = serializer.toString();
		return new GSString( string );
	}
	public function clone():GSFunction {
		if ( this.native ) {
			return this;
		} else {
			return new GSFunction(false, this.name, this.body, this.parameters, this.environment, this.environment.duplicate(this.scope));
		}
	}
	public function bind( owner:GSObject ):GSFunction {
		var copy = this.clone();
		copy.defaultThisValue = owner;
		return copy;
	}
	
//Overriden Methods
	override public function __getattr__( key:GSObject ):Null<GSObject> {
		var me = this;
		if ( key.type == 'string' ) {
			switch ( key.toString() ) {
				case "bind":
					return new GSFunction(true, function( data ) {
						return Reflect.callMethod(me, me.bind, data.args);
					});
				case "apply":
					return new GSFunction(true, function ( data ) {
						var theThisValue = cast( data.args[0], GSObject );
						var theArguments = [for (item in cast(data.args[1], GSArray).__iter__()) item];
						return me.__call__(theArguments, theThisValue);
					});
				case "clone":
					return new GSFunction(true, function( data ) {
						return me.clone();
					});
				case "dump":
					return new GSFunction(true, function( data ) {
						return me.dump();
					});
				case "__call__":
					return new GSFunction(true, function( data ) {
						return me.__call__( data.args, data.self );
					});
				case "__create__":
					return new GSFunction(true, function( data ) {
						return me.__create__( data.args );
					});
				case "prototype":
					return this.__prototype__;
				default:
					return super.__getattr__(key);
			}
		} else {
			throw 'TypeError: Function attribute keys can only be strings';
		}
	}
	override public function __setattr__( keyObj:GSObject, value:GSObject ) {
		var key = keyObj.toString();
		switch ( key ) {
			case "prototype":
				if ( value.type == 'object' )
					this.__prototype__ = value;
			default:
				super.__setattr__( keyObj, value );
		}
	}
	
//Constructor Invokation Function
	public function __create__( args:Array < GSObject > ) {
		var self = new GSObject();
		this.__call__( args, self );
		for ( name in this.__prototype__.keys() ) {
			var prop:GSObject = this.__prototype__.__getattr__(name);
			if ( prop.type == 'function' ) self.__setattr__(name, cast(prop, GSFunction).bind(self));
			else self.__setattr__(name, prop);
		}
		return self;
	}
}