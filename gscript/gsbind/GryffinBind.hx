package gscript.gsbind;

import gscript.typesystem.GSObject;
import gscript.typesystem.GSArray;
import gscript.typesystem.GSString;
import gscript.typesystem.GSNumber;
import gscript.typesystem.GSFunction;
import gscript.typesystem.TypeSystem;

class GryffinBind {
	public static function fromNative( obj:Dynamic ):Dynamic {
		var type:String = TypeSystem.basictype(obj);
		switch ( type ) {
			case "Null", "Bool": return obj;
			case "Int", "Float":
				return new GSNumber( obj );
			case "String":
				return new GSString( obj );
			case "Array":
				return GSArray.fromArray([for (x in cast(obj, Array<Dynamic>)) fromNative(x)]);
			case "Function":
				return new GSFunction(true, function( data ) {
					var nativeArgs:Array < Dynamic > = [for (x in cast(data.args, Array<Dynamic>)) toNative(x)];
					var retVal = Reflect.callMethod( null, obj, nativeArgs );
					return fromNative(retVal);
				});
			default:
				if (Reflect.isObject(obj)) {
					return new BoundObject(obj);
				} else {
					throw 'TypeError: Cannot bind objects of type $type to the GryffinScript type system.';
				}
		}
	}
	public static function toNative( obj:Dynamic ):Dynamic {
		var type:String = TypeSystem.basictype(obj);
		switch ( type ) {
			case "Null": return null;
			case "Bool": return obj;
			case "GSString", "GSNumber": return obj.value;
			case "GSArray":
				return [for (item in cast(obj.items, Array<Dynamic>)) toNative(item)];
			case "GSObject":
				var result:Dynamic = {};
				var keys:Iterator < Dynamic > = obj.__props__.keys();
				for ( key in keys ) {
					var value:Dynamic = obj.__props__.get(key).v;
					Reflect.setProperty(result, key, toNative(value));
				}
				return result;
			case "GSFunction":
				return Reflect.makeVarArgs(function( args:Array < Dynamic > ) {
					var gsArgs:Array < Dynamic > = [for (x in args) fromNative(x)];
					var retVal:Dynamic = obj.__invoke__( gsArgs );
					return toNative(retVal);
				});
			case "BoundObject":
				return toNative(obj.target);
			case "GSPointer":
				return toNative(obj.address);
			case "GSNativePointer":
				return obj.address;
			default:
				throw 'TypeError: Cannot unbind object of type $type from the GryffinScript type system';
				return null;
		}
	}
	
	public static function bindObject( obj:Dynamic ):GSObject {
		return new BoundObject( obj );
	}
	public static function bindClass( obj:Dynamic ):GSObject {
		return new BoundClass( obj );
	}
	
//Type Conversion Methods
	public static function parseArgs( args:Array < Dynamic >, types:Array < String > ):Array < Dynamic > {
		var newArgs:Array < Dynamic > = [];
		for ( i in 0...args.length ) {
			var arg = args[i];
			var dtype = types[i];
			newArgs.push(convertTo(arg, dtype));
		}
		return newArgs;
	}
	public static function convertTo( obj:Dynamic, dtype:String ):Dynamic {
		var check = parseTypeChecker(dtype);
		var native:Bool = (dtype.charAt(0).toUpperCase() == dtype.charAt(0));
		if (check(obj)) {
			return native ? fromNative(obj) : toNative(obj);
		} else {
			invalidArg( obj, dtype );
		}
	}
	public static function checkType( obj:Dynamic, type:String ):Bool {
		if ( obj == null ) return (type == 'null');
		else if ( obj == true || obj == false ) return (type == 'bool' || type == 'Bool');
		else if (Reflect.getProperty(obj, 'type') != null) {
			return (obj.type == type);
		}
		else {
			return (TypeSystem.basictype(obj) == type);
		}
	}
	public static function parseTypeChecker( dtype:String ):Dynamic -> Bool {
		var gryffinMode:Bool = (dtype.charAt(0).toUpperCase() != dtype.charAt(0));
		//If type description contains 'or' expressions
		if ( dtype.indexOf('|') != -1 ) {
			var acceptibleTypes = dtype.split('|');
			var checks = [for (t in acceptibleTypes) parseTypeChecker(t)];
			return function( x:Dynamic ):Bool {
				for ( f in checks ) if (!f(x)) return false;
				return true;
			};
		} else {
			//If type description has <[Type]> parameters
			if ( dtype.indexOf('<') != -1 ) {
				var childType = dtype.substring(dtype.indexOf('<'), dtype.lastIndexOf('>')+1);
				var mainType = dtype.substring(0, dtype.indexOf('<')-1);
				var checkChild = parseTypeChecker(childType);
				return function( obj:Dynamic ):Bool {
					var iter = (function():Void -> Iterator<Dynamic> {
						if (Reflect.getProperty(obj, 'iterator') != null) return Reflect.getProperty(obj, 'iterator');
						else if (Reflect.getProperty(obj, '__iter__') != null) return Reflect.getProperty(obj, '__iter__');
						else throw 'TypeError:  No iterator found.';
					}());
					if (checkType(obj, mainType)) {
						for (x in iter()) {
							if (!checkChild(x)) return false;
						}
						return true;
					} else {
						return false;
					}
				};
			} else {
				return function( obj:Dynamic ):Bool {
					return checkType(obj, dtype);
				};
			}
		}
	}
	
	private static inline function invalidArg( arg:Dynamic, desiredType:String ):Void {
		throw 'TypeError: Expected \'$desiredType\', got $arg';
	}
	
}