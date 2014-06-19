package gscript.gsbind;

enum GryfType {
	TNumber;
	TString;
	TArray( type:String );
	TObject( fields:Array<Array<String>> );
	TFunction( rType:String );
}