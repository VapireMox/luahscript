package luahscript.exprs;

typedef LuaElseIf = {
	var cond:LuaExpr;
	var body:LuaExpr;
}

typedef LuaExpr = {
	var expr:LuaExprDef;
	var line:Int;
}

typedef LuaTableConstructor = {
	var v: LuaExpr;
	var ?key:LuaExpr;
	var ?haveBK:Bool;
	var ?endSemicolon:Bool;
}

enum LuaExprDef {
	EConst(c:LuaConst);
	EIdent(v:String);
	ELabel(label:String, ?doit:LuaExpr);
	EGoto(label:String);
	EParent(e:LuaExpr);
	EField(e:LuaExpr, f:String, ?isDouble:Bool);
	ELocal(e:LuaExpr);
	EBinop(op:String, e1:LuaExpr, e2:LuaExpr);
	EPrefix(prefix:String, e:LuaExpr);
	ECall(e:LuaExpr, params:Array<LuaExpr>);
	ETd(ae:Array<LuaExpr>);
	EAnd(ae:Array<LuaExpr>);
	EIf(cond:LuaExpr, body:LuaExpr, ?eis:Array<LuaElseIf>, ?eel:LuaExpr);
	ERepeat(body:LuaExpr, cond:LuaExpr);
	EWhile(cond:LuaExpr, e:LuaExpr);
	EForNum(v:String, body:LuaExpr, start:LuaExpr, end:LuaExpr, ?step:LuaExpr);
	EForGen(body:LuaExpr, iterator:LuaExpr, k:String, ?v:String);
	EBreak;
	EContinue;
	EFunction(args:Array<String>, e:LuaExpr, ?info:{var names:Array<String>; var isDouble:Bool;});
	EIgnore;
	EReturn(?e:LuaExpr);
	EArray(e:LuaExpr, index:LuaExpr);
	ETable(fl:Array<LuaTableConstructor>);
}