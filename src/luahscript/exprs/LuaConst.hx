package luahscript.exprs;

enum LuaConst {
	CInt(sb:Int);
	CFloat(sb:Float);
	CString(str:String, slk:StringLiteralKind);
	CTripleDot;
}