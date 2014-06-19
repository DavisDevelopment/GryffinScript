package gscript;

import gscript.Expr;
import gscript.typesystem.GSObject;
import gscript.typesystem.GSArray;
import gscript.typesystem.GSString;
import gscript.typesystem.GSNumber;
import gscript.typesystem.GSFunction;
import gscript.typesystem.GSPointer;
import gscript.typesystem.TypeSystem;

private enum Stop {
	SBreak;
	SContinue;
	SReturn( v : Dynamic );
}

class Interp {

	#if haxe3
	public var variables : Map<String,Dynamic>;
	public var locals : Map<String,{ r : Dynamic }>;
	public var binops : Map<String, Expr -> Expr -> Dynamic >;
	#else
	public var variables : Hash<Dynamic>;
	public var locals : Hash<{ r : Dynamic }>;
	public var binops : Hash< Expr -> Expr -> Dynamic >;
	#end
	
	var declared : Array<{ n : String, old : { r : Dynamic } }>;

	public function new() {
		#if haxe3
		locals = new Map();
		variables = new Map<String,Dynamic>();
		#else
		locals = new Hash();
		variables = new Hash();
		#end
		declared = new Array();
		variables.set("null",null);
		variables.set("true",true);
		variables.set("false",false);
		variables.set("trace",function(e) haxe.Log.trace(Std.string(e),cast { fileName : "gscript", lineNumber : 0 }));
		initOps();
	}

	function initOps() {
		var me = this;
		#if haxe3
		binops = new Map();
		#else
		binops = new Hash();
		#end
		
		var opMap = [
			"+" => "__add__",
			"-" => "__sub__",
			"*" => "__mul__",
			"/" => "__div__",
			"%" => "__mod__",
			"<<" => "__lshift__",
			">>" => "__rshift__",
			"&" => "__and__",
			"|" => "__or__",
			"&&" => "__land__",
			"||" => "__lor__",
			"==" => "__eq__",
			"!=" => "__ne__",
			"<" => "__lt__",
			">" => "__gt__",
			"<=" => "__le__",
			">=" => "__ge__",
			"+=" => "__iadd__",
			"-=" => "__isub__",
			"*=" => "__imul__",
			"/=" => "__idiv__"
		];
		
		//Math Ops
		
		for ( k in opMap.keys() ) {
			var boolOp:Bool = Lambda.has(["||", "&&"], k);
			binops.set(k, function ( e1, e2 ):Dynamic {
				var methodName:String = opMap.get(k);
				var isBool:Dynamic -> Bool = function(x:Dynamic) return (Std.is(x, Bool) || x == null);
				var obj1:Dynamic = me.expr(e1);
				var obj2:Dynamic = me.expr(e2);
				var OneBool:Bool = isBool(obj1);
				var TwoBool:Bool = isBool(obj2);
				
				if ( OneBool == false && TwoBool == false ) return Reflect.callMethod( obj1, Reflect.getProperty(cast(obj1, GSObject), methodName), [obj2] );
				else if ( OneBool && !TwoBool ) return Reflect.callMethod( obj2, Reflect.getProperty(cast(obj2, GSObject), methodName), [obj1] );
				else if ((!OneBool && TwoBool) || (!OneBool && !TwoBool)) return Reflect.callMethod( obj1, Reflect.getProperty(cast(obj1, GSObject), methodName), [obj2] );
				else {
					trace('This is going to be a null pointer! [$OneBool, $TwoBool]');
					return (([
						"==" => function( x, y ) return (x == y),
						"!=" => function( x, y ) return (x != y)
					]).get(k))( obj1, obj2 );
				}
			});
		}
		binops.set( "=", assign );
		
		//Augmented Assignment
		assignOp("%=",function(v1:Float,v2:Float) return v1 % v2);
		assignOp("&=",function(v1,v2) return v1 & v2);
		assignOp("|=",function(v1,v2) return v1 | v2);
		assignOp("^=",function(v1,v2) return v1 ^ v2);
		assignOp("<<=",function(v1,v2) return v1 << v2);
		assignOp(">>=",function(v1,v2) return v1 >> v2);
	}

	function assign( e1 : Expr, e2 : Expr ) : Dynamic {
		var v = expr(e2);
		switch( e1 ) {
		case EIdent(id):
			var l = locals.get(id);
			if( l == null ) {
				var o = variables.get(id);
				if ( o != null ) {
					if (o.type == 'pointer') Reflect.callMethod(o, Reflect.getProperty(o, '__reassign__'), [v]);
					else variables.set(id, v);
				} else {
					variables.set(id, v);
				}
			} else {
				var o = l.r;
				if (o.type == 'pointer') Reflect.callMethod(o, Reflect.getProperty(o, '__reassign__'), [v]);
				else l.r = v;
			}
		case EField(e,f):
			v = expr(e).__setattr__(new GSString(f), v);
		case ERefAccess( pt, f ):
			this.expr(pt).__pset__(this.expr(f), v);
		case EArray(e,index):
			expr(e).__setitem__(expr(index), v);
		default: throw Error.EInvalidOp("=");
		}
		return v;
	}

	function assignOp( op, fop : Dynamic -> Dynamic -> Dynamic ) {
		var me = this;
		binops.set(op,function(e1,e2) return me.evalAssignOp(op,fop,e1,e2));
	}

	function evalAssignOp(op,fop,e1,e2) : Dynamic {
		var v;
		switch( e1 ) {
		case EIdent(id):
			var l = locals.get(id);
			v = fop(expr(e1),expr(e2));
			if( l == null )
				variables.set(id,v)
			else
				l.r = v;
		case EField(e,f):
			var obj = expr(e);
			v = fop(get(obj,f),expr(e2));
			v = set(obj,f,v);
		case EArray(e,index):
			var arr = expr(e);
			var index = expr(index);
			v = fop(arr[index],expr(e2));
			arr[index] = v;
		default:
			throw Error.EInvalidOp(op);
		}
		return v;
	}

	function increment( e : Expr, prefix : Bool, delta : Int ) : Dynamic {
		switch(e) {
		case EIdent(id):
			var l = locals.get(id);
			var v : Dynamic = (l == null) ? variables.get(id) : l.r;
			if( prefix ) {
				v += delta;
				if( l == null ) variables.set(id,v) else l.r = v;
			} else
				if( l == null ) variables.set(id,v + delta) else l.r = v + delta;
			return v;
		case EField(e,f):
			var obj = expr(e);
			var v : Dynamic = get(obj,f);
			if( prefix ) {
				v += delta;
				set(obj,f,v);
			} else
				set(obj,f,v + delta);
			return v;
		case EArray(e,index):
			var arr = expr(e);
			var index = expr(index);
			var v = arr[index];
			if( prefix ) {
				v += delta;
				arr[index] = v;
			} else
				arr[index] = v + delta;
			return v;
		default:
			throw Error.EInvalidOp((delta > 0)?"++":"--");
		}
	}

	public function execute( expr : Expr ) : Dynamic {
		#if haxe3
		locals = new Map();
		#else
		locals = new Hash();
		#end
		return exprReturn(expr);
	}

	public function exprReturn(e) : Dynamic {
		try {
			return expr(e);
		} catch( e : Stop ) {
			switch( e ) {
			case SBreak: throw "Invalid break";
			case SContinue: throw "Invalid continue";
			case SReturn(v): return v;
			}
		}
		return null;
	}

	public function duplicate<T>( h : #if haxe3 Map < String, T > #else Hash<T> #end ) {
		#if haxe3
		var h2 = new Map();
		#else
		var h2 = new Hash();
		#end
		for( k in h.keys() )
			h2.set(k,h.get(k));
		return h2;
	}

	function restore( old : Int ) {
		while( declared.length > old ) {
			var d = declared.pop();
			locals.set(d.n,d.old);
		}
	}
	
	function resolve( id : String ) : Dynamic {
		var l = locals.get(id);
		if( l != null )
			return l.r;
		var v = variables.get(id);
		if( v == null && !variables.exists(id) )
			throw Error.EUnknownVariable(id);
		return v;
	}

	public function expr( e : Expr ) : Dynamic {
		switch( e ) {
		case EConst(c):
			switch( c ) {
			case CInt(v):
				var o = new GSNumber(v);
				o.initMethods();
				return o;
			case CFloat(f):
				var o = new GSNumber(f);
				o.initMethods();
				return o;
			case CString(s):
				var o = new GSString(s);
				o.initMethods();
				return o;
			#if !haxe3
			case CInt32(v): return v;
			#end
			}
		case EIdent(id):
			return resolve(id);
		case EVar(n,_,e):
			declared.push({ n : n, old : locals.get(n) });
			locals.set(n,{ r : (e == null)?null:expr(e) });
			return null;
		case EParent(e):
			return expr(e);
		case EBlock(exprs):
			var old = declared.length;
			var v = null;
			for( e in exprs )
				v = expr(e);
			restore(old);
			return v;
		case EField(e,f):
			return expr(e).__getattr__(new GSString(f));
			
		//Pointer Operator "->"
		case ERefAccess( e, e2 ):
			var obj:Dynamic = this.expr(e);
			var ref:Dynamic = null;
			switch ( e2 ) {
				case EIdent(id):
					ref = new GSString(id);
					ref.initMethods();
				default:
					ref = this.expr(e2);
			}
			if (!(Std.is(obj, Bool) || obj == null)) {
				var pointerAccess = Reflect.getProperty(obj, "__pget__");
				return Reflect.callMethod(obj, pointerAccess, [ref]);
			} else {
				throw 'TypeError: Cannot use pointer operator on Boolean or Null values';
				return null;
			}
		case EBinop(op,e1,e2):
			var fop = binops.get(op);
			if( fop == null ) throw Error.EInvalidOp(op);
			return fop(e1,e2);
/*
----Unary Operators----
-----------------------
*/
		case EUnop(op,prefix,e):
			switch(op) {
			case "!":
				var obj:Dynamic = expr(e);
				if ( obj == null || obj == true || obj == false ) return (obj != true);
				else {
					var method = Reflect.getProperty(obj, "__invert__");
					return Reflect.callMethod(obj, method, []);
				}
			case "-":
				return -expr(e);
			case "++":
				return increment(e,prefix,1);
			case "--":
				return increment(e,prefix,-1);
			case "~":
				#if (neko && !haxe3)
				return haxe.Int32.complement(expr(e));
				#else
				return ~expr(e);
				#end
			//Reference Operator
			case "&":
				var obj = this.expr(e);
				return new GSPointer(obj, this);
			//Dereference Operator
			case "*":
				var obj:Dynamic = this.expr(e);
				if (TypeSystem.basictype(obj) != "GSPointer") throw 'InvalidOp "*":  Cannot dereference $obj';
				return obj.address;
			default:
				throw Error.EInvalidOp(op);
			}
		case ECall(e,params):
			var args = new Array();
			for( p in params )
				args.push(expr(p));
			switch(e) {
			case EField( e, f ):
				var obj = expr(e);
				var method = obj.__getattr__(new GSString(f));
				if ( method != null ) return method.__invoke__(args);
				else throw 'TypeError: Invalid call to $e -> $f';
			case EArray( e, index ):
				var obj = expr(e);
				if ( obj == null ) throw Error.EInvalidAccess(Std.string(expr(index)));
				this.fcall( obj, expr(index), args );
			default:
				return expr(e).__invoke__( args );
			}
		case EIf(econd,e1,e2):
			return if( expr(econd) == true ) expr(e1) else if( e2 == null ) null else expr(e2);
		case EWhile(econd,e):
			whileLoop(econd,e);
			return null;
		case EFor(v,it,e):
			forLoop(v,it,e);
			return null;
		case EBreak:
			throw SBreak;
		case EContinue:
			throw SContinue;
		case EReturn(e):
			throw SReturn((e == null)?null:expr(e));
		case EFunction( params, fexpr, name, _ ):
			var capturedLocals = duplicate( locals );
			var me = this;
			var funcName:Null< GSString > = null;
			if ( name != null )
				funcName = new GSString( name );
			var f = new GSFunction ( false, funcName, fexpr, params, me, capturedLocals );
			if( name != null )
				variables.set(name,f);
			return f;
		case EArrayDecl(arr):
			var a = new GSArray();
			a.initMethods();
			for( e in arr )
				a.push(expr(e));
			return a;
		case EArray(e, index):
			return expr(e).__getitem__(expr(index));
		case ENew(cl,params):
			var a:Array < GSObject > = new Array();
			for( e in params )
				a.push(expr(e));
			return cnew( cl, a );
		case EDelete( e ):
			switch ( e ) {
				case EIdent( id ):
					var obj = expr(e);
					try {
						return obj.__delete__();
					} catch ( error : String ) return false;
				case EField( o, f ):
					var obj = expr(o);
					try {
						return obj.__deleteattr__( f );
					} catch ( error:String ) return false;
				case EArray( a, i ):
					var array = expr(a);
					var index = expr(i);
					try {
						return array.__deleteitem__( index );
					} catch ( error:String ) return false;
				default:
					throw 'Unexpected $e';
			}
		case EThrow(e):
			throw expr(e);
		case ETry(e,n,_,ecatch):
			var old = declared.length;
			try {
				var v : Dynamic = expr(e);
				restore(old);
				return v;
			} catch( err : Stop ) {
				throw err;
			} catch( err : Dynamic ) {
				// restore vars
				restore(old);
				// declare 'v'
				declared.push({ n : n, old : locals.get(n) });
				locals.set(n,{ r : err });
				var v : Dynamic = expr(ecatch);
				restore(old);
				return v;
			}
		case EObject(fl):
			var o = new GSObject();
			o.initMethods();
			for( f in fl )
				o.__setitem__(new GSString(f.name), expr(f.e));
			return o;
		case ETernary(econd,e1,e2):
			return if( expr(econd) == true ) expr(e1) else expr(e2);
		}
		return null;
	}

	function whileLoop(econd,e) {
		var old = declared.length;
		while( expr(econd) == true ) {
			try {
				expr(e);
			} catch( err : Stop ) {
				switch(err) {
				case SContinue:
				case SBreak: break;
				case SReturn(_): throw err;
				}
			}
		}
		restore(old);
	}

	function makeIterator( v : Dynamic ) : Iterator<Dynamic> {
		try {
			v = v.__iter__();
		} catch ( error : String ) {
			throw Error.EInvalidIterator(v);
		}
		if( v.hasNext == null || v.next == null ) throw Error.EInvalidIterator(v);
		return v;
	}

	function forLoop(n,it,e) {
		var old = declared.length;
		declared.push({ n : n, old : locals.get(n) });
		var it = makeIterator(expr(it));
		while( it.hasNext() ) {
			locals.set(n,{ r : it.next() });
			try {
				expr(e);
			} catch( err : Stop ) {
				switch( err ) {
				case SContinue:
				case SBreak: break;
				case SReturn(_): throw err;
				}
			}
		}
		restore(old);
	}
	
	public function callable( o : Dynamic, ?f:String ):Bool {
		var field = null;
		if ( f != null )
			field = o.__getattr__(new GSString(f));
		else
			if ( o == null ) return false;
			field = o;
		if ( field == null ) field = Reflect.getProperty( o, f );
		if ( field == null ) return false;
		else {
			if (Reflect.isFunction(field) || TypeSystem.basictype(field) == "GSFunction") return true;
			else {
				return callable( field, "__call__" );
			}
		}
	}
	function constructible( o:Dynamic ):Bool {
		return callable( o, "__create__" );
	}

	function get( o : Dynamic, f : String ) : Dynamic {
		if( o == null ) throw Error.EInvalidAccess(f);
		var res:Dynamic = o.__getattr__(new GSString(f));
		if ( res == null ) res = Reflect.getProperty( o, f );
		return res;
	}

	function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
		if( o == null ) throw Error.EInvalidAccess(f);
		Reflect.setField(o,f,v);
		return v;
	}

	function fcall( o : GSObject, f : String, args : Array<Dynamic> ) : Dynamic {
		return o.__callmethod__(new GSString(f), args);
	}

	function cnew( cl : String, args : Array < GSObject > ) : Dynamic {
		var klass = this.variables.get(cl);
		if ( klass == null ) {
			var l = this.locals.get(cl);
			if ( l != null ) klass = l.r;
		}
		if ( klass == null ) {
			var e = new Parser().parseString(cl);
			var obj = this.expr(e);
			if ( obj != null ) klass = obj;
		}
		if ( klass == null ) throw 'ReferenceError: $cl is undefined';
		if (klass.__getattr__(new GSString("__create__")) != null) {
			var constructor:GSObject = klass.__getattr__(new GSString("__create__"));
			return constructor.__invoke__( args );
		}
		return null;
	}

}