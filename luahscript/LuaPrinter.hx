package luahscript;

import luahscript.exprs.LuaError;

class LuaPrinter {
	public static function errorToString(e: LuaError, showPos: Bool = true) {
		var message = switch (e.err) {
			case EInvalidChar(c): "expected char near '<" + (StringTools.isEof(c) ? "eof" : Std.string(c)) + ">";
			case EUnexpected(s): "expected symbol near '" + s + "'";
			case EUnterminatedString(c): "unfinished string near '<\\" + (StringTools.isEof(c) ? "eof" : Std.string(c)) + ">'";
			case EUnterminatedComment: "unfinished long comment near <eof>";
			case ECallNilValue(v, type): "attempt to call a nil value" + (type != UNKNOWN ? " (" + type + " '" + v + "')" : "");
			case EInvalidOp(op): "unexpected symbol near '" + op + "'";
			case EInvalidIterator(v): "attempt to call a invalid value (for iterator)";
			case EInvalidAccess(f, type): "attempt to index a nil value" + (type != UNKNOWN ? " (" + type + " '" + f + "')" : "");
			case ECustom(msg): msg;
			default: "Unknown Error.";
		};
		if (showPos)
			return e.line + ": " + message;
		else
			return message;
	}
}