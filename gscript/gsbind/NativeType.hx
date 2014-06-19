package gscript.gsbind;

enum NativeType {
	NNumber;
	NFloat;
	NInt;
	NString;
	NArray( type:String );
	NObject( fields:Array <{ key:String, type:String }> );
	NFunction( params:Array < String >, rType:String );
}