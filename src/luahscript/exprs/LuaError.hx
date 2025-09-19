package luahscript.exprs;

import luahscript.LuaInterp;

class LuaError {
	public var err: LuaErrorDef;
	public var line: Int;

	public function new(e:LuaErrorDef, line:Int) {
		this.err = e;
		this.line = line;
	}

	public function toString():String {
		return luahscript.LuaPrinter.errorToString(this);
	}
}

enum LuaErrorDef
{
	EInvalidChar(c:Int);
	EUnexpected(s:String, ?ex:String);
	EUnterminatedString(char:Int);
	EUnterminatedComment;
	ECallInvalidValue(id:String, type:LuaVariableType, td:LuaTyper);
	EInvalidOp(op:String);
	EInvalidIterator(v:LuaTyper);
	EInvalidAccess(f:String, type:LuaVariableType, td:LuaTyper);
	ECustom(msg:String);
}

enum abstract LuaVariableType(String) to String {
	var GLOBAL:LuaVariableType = "global";
	var LOCAL:LuaVariableType = "Local";
	var FIELD:LuaVariableType = "Field";
	var UNKNOWN:LuaVariableType = "";
}