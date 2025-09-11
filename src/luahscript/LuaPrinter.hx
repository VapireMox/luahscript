package luahscript;

import luahscript.exprs.LuaExpr;
import luahscript.exprs.*;
using StringTools;

/**
 * 印刷配置
 */
typedef LuaPrinterConfigure = {
	/**
	 * 是否缩进
	 */
	var ?indent:Bool;
	/**
	 * 是否填入分号
	 */
	var ?semicolon:Bool;
	/**
	 * 是否缩进使用`tab`代替，默认为空格
	 */
	var ?indentUseTab:Bool;
	/**
	 * 是否将代码印刷集中于一行
	 */
	var ?focusOneLine:Bool;
	/**
	 * 缩进空格字符数量
	 */
	var ?indentSpaceChar:Int;
	/**
	 * 强迫症必备神器
	 */
	var ?normative:Bool;
	/**
	 * 印刷水印
	 */
	var ?waterMark:Bool;
}

class LuaPrinter {
	private var cnm:String;

	var buf:StringBuf;
	var indentCounts:String;
	private var indents:Array<String>;

	var configure:LuaPrinterConfigure;

	public function new(?pc:LuaPrinterConfigure) {
		if(pc != null) {
			final ec = getDefaultConfigure();
			pc.indent = pc.indent ?? ec.indent;
			pc.semicolon = pc.semicolon ?? ec.semicolon;
			pc.indentUseTab = pc.indentUseTab ?? ec.indentUseTab;
			pc.focusOneLine = pc.focusOneLine ?? ec.focusOneLine;
			pc.indentSpaceChar = pc.indentSpaceChar ?? ec.indentSpaceChar;
			pc.waterMark = pc.waterMark ?? ec.waterMark;
			this.configure = pc;
		} else this.configure = getDefaultConfigure();

		cnm = if(this.configure.indentUseTab) {
			"\t";
		} else {
			var s = "";
			for(i in 0...this.configure.indentSpaceChar) {
				s += " ";
			}
			s;
		};
	}

	public function print(expr:LuaExpr):String {
		indents = [];
		buf = new StringBuf();
		if(this.configure.waterMark) {
			add("-- Print by Luahscript. Its very NB!");
			add("\n");
		}
		exprToString(expr);
		return buf.toString();
	}

	function exprToString(expr:LuaExpr) {
		if(expr == null) return add("<<NULL>>");
		if(expr.expr == null) return add("<<NULL>>");
		switch(expr.expr) {
			case EConst(c):
				constToString(c);
			case EGoto(l):
				add("goto ");
				add(l);
			case ELabel(label, doit):
				add("::" + (this.configure.normative ? " " : ""));
				add(label);
				add((this.configure.normative ? " " : "") + "::");
				if(doit != null) {
					if(!this.configure.focusOneLine && this.configure.normative) add("\n" + indentCounts + "do");
					else add(" do");
					exprToString(doit);
					add("end");
				}
			case EIdent(v):
				add(v);
			case EParent(e):
				add("(");
				exprToString(e);
				add(")");
			case EField(e, f, isDouble):
				exprToString(e);
				add(if(isDouble == true) ":" else ".");
				add(f);
			case ELocal(e):
				add("local ");
				exprToString(e);
			case EBinop(op, e1, e2):
				exprToString(e1);
				if(op == "or" || op == "and" || configure.normative) add(" " + op + " "); else add(op);
				exprToString(e2);
			case EPrefix(prefix, e):
				add(prefix + if(prefix == "not" || (configure.normative && !(prefix == "#" || prefix == "-"))) " " else "");
				exprToString(e);
			case ECall(e, params):
				exprToString(e);
				add("(");
				for(i=>p in params) {
					exprToString(p);
					if(i < params.length - 1) {
						add(",");
						if(configure.normative) add();
					}
				}
				add(")");
			case ETd(ae):
				if(!this.configure.focusOneLine) add("\n");
				else add();
				increaseIndent();
				for(i=>e in ae) {
					if(!this.configure.focusOneLine) add(indentCounts);
					exprToString(e);
					if(this.configure.semicolon) add(";");
					if(this.configure.focusOneLine) add();
					else {
						add("\n");
					}
				}
				originalSimplicityIndent();
				if(!this.configure.focusOneLine) add(indentCounts);
			case EAnd(ae):
				for(i=>e in ae) {
					exprToString(e);
					if(i < ae.length - 1) {
						add(",");
						if(this.configure.normative) add();
					}
				}
			case EIf(cond, body, eis, eel):
				add("if ");
				exprToString(cond);
				if(!this.configure.focusOneLine && this.configure.normative) add("\n" + indentCounts + "then");
				else add(" then");
				exprToString(body);
				if(eis != null) for(byd in eis) {
					add("elseif ");
					exprToString(byd.cond);
					if(!this.configure.focusOneLine && this.configure.normative) add("\n" + indentCounts + "then")
					else add(" then");
					exprToString(byd.body);
				}
				if(eel != null) {
					add("else");
					exprToString(eel);
				}
				add("end");
			case ERepeat(body, cond):
				add("repeat");
				exprToString(body);
				add("until ");
				exprToString(cond);
			case EWhile(cond, e):
				add("while ");
				exprToString(cond);
				if(!this.configure.focusOneLine && this.configure.normative) add("\n" + indentCounts + "do")
				else add(" do");
				exprToString(e);
				add("end");
			case EForNum(v, body, start, end, step):
				add("for ");
				if(this.configure.normative) add(v + " = ");
				else add(v + "=");
				exprToString(start);
				add(this.configure.normative ? ", " : ",");
				exprToString(end);
				if(step != null) {
					add(this.configure.normative ? ", " : ",");
					exprToString(step);
				}
				if(!this.configure.focusOneLine && this.configure.normative) add("\n" + indentCounts + "do")
				else add(" do");
				exprToString(body);
				add("end");
			case EForGen(body, iterator, k, v):
				add("for ");
				add(k);
				if(v != null) {
					add(this.configure.normative ? ", " : ",");
					add(v);
				}
				add(" in ");
				exprToString(iterator);
				if(!this.configure.focusOneLine && this.configure.normative) add("\n" + indentCounts + "do")
				else add(" do");
				exprToString(body);
				add("end");
			case EBreak:
				add("break");
			case EContinue:
				add("continue");
			case EFunction(args, e, info):
				add("function");
				if(info != null) {
					if(info.names.length > 0) add();
					for(i=>n in info.names) {
						add(n);
						if(i < info.names.length - 1) add((info.isDouble ? ":" : "."));
					}
				}
				add("(");
				for(i=>arg in args) {
					add(arg);
					if(i < args.length - 1) {
						add(",");
						if(this.configure.normative) add();
					}
				}
				add(")");
				exprToString(e);
				add("end");
			case EIgnore:
			case EReturn(e):
				add("return");
				if(e != null) {
					add();
					exprToString(e);
				}
			case EArray(e, index):
				exprToString(e);
				add("[");
				exprToString(e);
				add("]");
			case ETable(fl):
				add("{");
				for(i=>byd in fl) {
					if(byd.key != null) {
						if(byd.haveBK == true) {
							add("[");
							exprToString(byd.key);
							add("]");
						} else {
							exprToString(byd.key);
						}
						if(this.configure.normative) {
							add(" = ");
						} else add("=");
					}
					exprToString(byd.v);
					if(i < fl.length - 1) {
						add((byd.endSemicolon == true ? ";" : ","));
						if(this.configure.normative) add();
					}
				}
				add("}");
		}
	}

	function constToString(c:LuaConst) {
		switch(c) {
			case CInt(sb):
				add(Std.string(sb));
			case CFloat(sb):
				add(Std.string(sb));
			case CString(str, slk):
				switch(slk) {
					case DoubleQuotes:
						add('"');
						add(str.replace("\n", "\\n")
							.replace("\t", "\\t")
							.replace("\"", "\\\"")
							.replace("\r", "\\r")
						);
						add('"');
					case SingleQuotes:
						add("'");
						add(str.replace("\n", "\\n")
							.replace("\t", "\\t")
							.replace("'", "\\'")
							.replace("\r", "\\r")
						);
						add("'");
					case SquareBracket(count):
						var a = "";
						for(i in 0...count) a += "=";
						add("[" + a + "[");
						add(str);
						add("]" + a + "]");
				}
			case CTripleDot:
				add("...");
		}
	}

	inline function add(str:String = " ") {
		buf.add(str);
	}

	function increaseIndent() {
		if(configure.indent && !configure.focusOneLine) indents.push(cnm);
		indentCounts = indents.join("");
	}

	function originalSimplicityIndent() {
		if(configure.indent && !configure.focusOneLine) indents.pop();
		indentCounts = indents.join("");
	}

	private static inline function getDefaultConfigure():LuaPrinterConfigure {
		// i dont like this def configure, but its enough. >:|
		return {
			indent: true,
			semicolon: false,
			indentUseTab: false,
			focusOneLine: false,
			indentSpaceChar: 2,
			waterMark: true,
			normative: false,
		};
	}

	public static function errorToString(e: LuaError, showPos: Bool = true) {
		var message = switch (e.err) {
			case EInvalidChar(c): "expected char near " + (StringTools.isEof(c) ? "'<\\eof>'" : Std.string(luahscript.LuaParser.inLu(c) ? "'" + String.fromCharCode(c) + "'" : "'<\\" + Std.string(c) + ">'"));
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