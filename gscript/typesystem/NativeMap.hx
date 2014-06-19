package gscript.typesystem;

class NativeMap < K, T > {
	public var keyList:Array <K>;
	public var values:Array <T>;
	
	public function new() {
		this.keyList = new Array();
		this.values = new Array();
	}
	public function exists( key:K ):Bool {
		var i:Int = Lambda.indexOf(this.keyList, key);
		if ( i != -1 ) return true;
		return false;
	}
	public function get( key:K ):Null<T> {
		var i:Int = Lambda.indexOf(this.keyList, key);
		if ( i != -1 ) return this.values[i];
		return null;
	}
	public function set( key:K, value:T ):Void {
		if (this.exists(key)) {
			var i:Int = Lambda.indexOf(this.keyList, key);
			this.values[i] = value;
		} else {
			this.keyList.push(key);
			this.values.push(value);
		}
	}
	public function remove( key:K ):Bool {
		var i:Int = Lambda.indexOf(this.keyList, key);
		if ( i != -1 ) {
			this.keyList.remove(key);
			this.values.remove(this.values[i]);
			return true;
		} else {
			return false;
		}
	}
	public function iterator():Iterator < T > {
		return this.values.iterator();
	}
	public function keys():Iterator < K > {
		return this.keyList.iterator();
	}
}