package gscript.typesystem;

class TypeSystem {
	public static function basictype( obj:Dynamic ):String {
		switch ( obj ) {
			case "": return "String";
				
			default:
				if ( Reflect.isObject(obj) ) {
					var klass = Type.getClass( obj );
					if ( klass == null ) {
						if ( Reflect.getProperty(obj, "__proto__") != null ) {
							var proto = Reflect.getProperty(obj, "__proto__");
							if ( Reflect.getProperty(proto, "constructor") != null ) return Reflect.getProperty(proto, "constructor").name;
							else return "Object";
						} else {
							try {
								return Type.getClassName(obj);
							} catch ( error:String ) {
								return "Object";
							}
						}
					}
					var klassName = Type.getClassName( klass );
					return klassName.substring(klassName.lastIndexOf('.')+1);
				}
				else if ( Reflect.getProperty(obj, "indexOf") != null ) {
					if ( Reflect.getProperty(obj, "join") != null ) return "Array";
					else return "String";
				}
				else if ( Reflect.isFunction(obj) ) return "Function";
				else if ( obj == null ) return "Null";
				else if ( obj == true || obj == false ) return "Bool";
				try {
					if ( obj + 0 == obj ) {
						var repr:String = Std.string(obj);
						if ( repr.indexOf('.') == -1 ) return "Int";
						else return "Float";
					}
				} catch ( error : String ) {
					"nope";
				}
				return "Unknown";
		}
	}
	public static function callable( o : Dynamic, ?f:String ):Bool {
		var obj:Dynamic = null;
		if ( f != null ) obj = o.__getattr__(new GSString(f));
		else
			obj = o;
		if ( obj == null ) return false;
		var callFunction = obj.__getattr__(new GSString('__call__'));
		if ( callFunction == null ) return false;
		if (Reflect.isFunction(callFunction)) return true;
		return false;
	}
}