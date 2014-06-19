package gscript.typesystem;

import gscript.gsbind.GryffinBind;

class GSNativePointer extends GSObject {
	public var address:Dynamic;
	public var interp:Interp;
	public var getters:Map<String, String -> Dynamic>;
	public var setters:Map<String, String -> Dynamic -> Void>;
	public var methods:Map<String, { args:Array<String>, ret:Null<String> }>;
	public var fields:Map<String, String>;
	
	public function new( obj:Dynamic, env:Interp ) {
		super();
		this.type = 'pointer';
		this.address = obj;
		this.interp = env;
		this.methods = new Map();
		this.fields = new Map();
		this.getters = new Map();
		this.setters = new Map();
	}
//Pointer Field Access
	override public function __pget__( k:Dynamic ):Dynamic {
		var me = this;
		var key:String = Std.string(k);
		var fieldType:String = this.fields.get(key);
		trace( key );
		if ( this.getters.exists(key) ) {
			return this.getters.get(key)('');
		} else {
			trace( key );
			if ( fieldType != null ) {
				var field = Reflect.getProperty(me.address, key);
				return GryffinBind.convertTo(field, fieldType);
			} else {
				var methodSpec:Dynamic = this.methods.get(key);
				var method:Dynamic = Reflect.getProperty( me.address, key );
				if ( methodSpec != null ) {
					return new GSFunction(true, function ( data ) {
						var nargs = GryffinBind.parseArgs( data.args, methodSpec.args );
						var ret = Reflect.callMethod( me.address, method, nargs );
						return if ( methodSpec.ret != null ) GryffinBind.convertTo(ret, methodSpec.ret) else null;
					});
				} else {
					return null;
				}
			}
		}
	}
//Pointer Field Assignment
	override public function __pset__( k:Dynamic, v:Dynamic ):Void {
		var me = this;
		var key:String = Std.string(k);
		if (this.setters.exists(key)) {
			var set = this.setters.get(key);
			set( k, v );
		} else {
			if (this.fields.exists(key)) {
				var fieldType = this.fields.get(key);
				if (GryffinBind.checkType(v, fieldType)) {
				
				}
			} else {
			
			}
		}
	}
	
//FFI Binding Methods
	public function getter( name:String, get:String -> Dynamic ):Void {
		this.getters.set(name, get);
	}
	public function setter( name:String, set:String -> Dynamic -> Void ):Void {
		this.setters.set(name, set);
	}
	public function method( name:String, argTypes:Array < String >, ?returnType:String ):Void {
		this.methods.set( name, {
			'args': argTypes,
			'ret' : returnType
		});
	}
	
	public function field( name:String, type:String ):Void {
		this.fields.set( name, type );
	}
	
//String Representation
	override public function toString():String {
		var type:String = TypeSystem.basictype(this.address);
		return 'Pointer -> $type[Native Code]';
	}
}