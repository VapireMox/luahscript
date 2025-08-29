package luahscript;

class LuaPrinter {
	public static function errorToString(e: LuaError, showPos: Bool = true) {
		var message = switch (e.err) {
			case EInvalidChar(c): "expected char near '<" + (StringTools.isEof(c) ? "eof" : Std.string(c)) + ">";
			case EUnexpected(s): "expected symbol near '" + s + "'";
			case EUnterminatedString(c): "unfinished string near '<\\" + (StringTools.isEof(c) ? "eof" : Std.string(c)) + ">'";
			case EUnterminatedComment: "unfinished long comment near <eof>";
			case ECallNilValue(v): "attempt to call a nil value (global '" + v + "' + )";
			case EInvalidOp(op): "unexpected symbol near '" + op + "'";
			case EInvalidAccess(f): "attempt to access a invalid value ('" + f + "')";
			case ECustom(msg): msg;
			default: "Unknown Error.";
		};
		if (showPos)
			return e.line + ": " + message;
		else
			return message;
	}
}

class LuaError {
	public var err: LuaErrorDef;
	public var line: Int;

	public function new(e:LuaErrorDef, line:Int) {
		this.err = e;
		this.line = line;
	}

	public function toString():String {
		return LuaPrinter.errorToString(this);
	}
}

enum LuaErrorDef
{
	EInvalidChar(c:Int);
	EUnexpected(s:String);
	EUnterminatedString(char:Int);
	EUnterminatedComment;
	ECallNilValue(id:String);
	EInvalidOp(op:String);
	EInvalidAccess(f:String);
	ECustom(msg:String);
}