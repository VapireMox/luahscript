package luahscript;

import luahscript.exprs.LuaExpr;
import luahscript.exprs.LuaError;
import luahscript.exprs.*;

class LuaParser {
	private static final logicOperators:Array<String> = ["and", "or", "not"];
	private static final keywords:Array<String> = ["if", "else", "elseif", "for", "while", "function", "then", "do", "local", "return", "repeat", "until", "end", "true", "false", "nil", "goto"];

	var content:String;

	var opPriority:Map<String, Int>;
	var opRightAssoc:Map<String, Bool>;

	var pos:Int;
	var line:Int = 1;
	var _tokens:haxe.ds.GenericStack<LuaToken>;
	var _token:LuaToken;

	var commaAnd:Bool = false;
	var needCall:Bool = false;

	var isLocal:Bool;
	var stackKeywords:Bool;
	var saveVariables:Array<String>;

	public function new() {
		var priorities = [
			["^"],
			["not", "#"],
			["*", "/", "//", "%"],
			["+", "-"],
			[".."],
			["<", ">", "<=", ">=", "~=", "=="],
			["and"],
			["or"],
			["="],
		];
		opPriority = new Map();
		opRightAssoc = new Map();
		for( i in 0...priorities.length )
			for( x in priorities[i] ) {
				opPriority.set(x, i);
				if( i == 8 ) opRightAssoc.set(x, true);
			}
		for(op in ["not", "#"]) {
			opPriority.set(op, -2);
		}
	}

	function initParser() {
		commaAnd = false;
		needCall = false;
		inObject = false;
		assignQuare = false;

		saveVariables = [];
		_tokens = new haxe.ds.GenericStack<LuaToken>();
		pos = 0;
		line = 1;
	}

	public function parseFromString(content:String):LuaExpr {
		initParser();

		this.content = content;
		var a:Array<LuaExpr> = new Array();
		while( true ) {
			var tk = token();
			if(tk == TEof) break;
			push(tk);
			parseFullExpr(a);
		}
		return mk(EFunction(["..."], mk(ETd(a), 1), {names: [], isDouble: false}), 1);
	}

	function getIdent():String {
		var tk = token();
		switch( tk ) {
		case TId(id): return id;
		default:
			unexpected(tk);
			return null;
		}
	}

	function parseFullExpr( exprs : Array<LuaExpr> ) {
		var e = parseExpr();
		exprs.push(e);

		var tk = token();
		if(tk != TSemicolon) {
			push(tk);
		}
	}

	function makePrefix(op:String, e:LuaExpr):LuaExpr {
		if(e == null)
			return mk(EPrefix(op, e));
		return switch(e.expr) {
			case EBinop(bop, e1, e2): mk(EBinop(bop, makePrefix(op, e1), e2));
			default: mk(EPrefix(op, e));
		}
	}

	function makeBinop(op, e1, e):LuaExpr {
		if(e == null) return mk(EBinop(op,e1,e));
		return switch(e.expr) {
			case EBinop(op2,e2,e3):
				if( opPriority.get(op) <= opPriority.get(op2) && !opRightAssoc.exists(op) )
					mk(EBinop(op2,makeBinop(op,e1,e2),e3));
				else
					mk(EBinop(op, e1, e));
			default:
				mk(EBinop(op,e1,e));
		}
	}

	var assignQuare:Bool;
	var inObject:Bool;
	function parseNextExpr(e1:LuaExpr, nonAccess:Bool = false, bracket:Bool = false):LuaExpr {
		var tk = token();
		switch(tk) {
			case TOp("=") if(inObject):
				push(tk);
				return e1;
			case TOp("=") if(assignQuare):
				//lua不允许多次赋值=，限制就摆在那儿
				return unexpected(tk);
			case TOp(op) if((!commaAnd || op != "=") && opPriority.get(op) > -1):
				var e2 = if(!assignQuare && op == "=") {
					final oaq = assignQuare;
					assignQuare = true;
					var e = parseExpr();
					assignQuare = oaq;
					e;
				} else {
					parseExpr();
				}
				return makeBinop(op, e1, e2);
			case TComma if(!commaAnd && !inObject):
				var ae = [e1];
				push(tk);
				commaAnd = true;
				ae = ae.concat(parseExprAnds());
				commaAnd = false;
				return parseNextExpr(mk(EAnd(ae)));
			case TDot, TDoubleDot if(!nonAccess):
				var field = getIdent();
				if(tk == TDoubleDot) needCall = true;
				return parseNextExpr(mk(EField(e1,field, tk == TDoubleDot)));
			case TPOpen:
				var retional = false;
				LuaTools.recursion(e1, function(e) {
					switch(e.expr) {
						case EIdent(_):
							retional = true;
						case EField(_, _):
							retional = true;
						case EFunction(_, _):
							retional = true;
						case EArray(_, _):
							retional = true;
						case ECall(_, _):
							retional = true;
						case _:
					}
				});
				if(!retional) return unexpected(tk);
				needCall = false;
				return parseNextExpr(mk(ECall(e1,parseExprList(TPClose))));
			case TBkOpen:
				var e2 = parseExpr();
				ensure(TBkClose);
				return parseNextExpr(mk(EArray(e1,e2)));
			case _:
				if(needCall) unexpected(tk, TPOpen);
				push(tk);
				if(bracket) if(tk.match(TConst(CString(_, _))) || tk.match(TBrOpen)) {
					var arg = parseExpr();
					return parseNextExpr(mk(ECall(e1, [arg])));
				}
				return e1;
		}
	}

	function parseExpr(?getValue:Bool = false):LuaExpr {
		var tk = token();
		return switch(tk) {
			case TId("goto") if(!getValue):
				final label = getIdent();
				mk(EGoto(label));
			case TId(id) if(id == "true" || id == "false" || id == "nil"):
				return parseNextExpr(mk(EIdent(id)));
			case TId(id) if(getValue && (id == "function" || (!logicOperators.contains(id) && !keywords.contains(id)))):
				parseNextExpr(parseIdent(id), false, id != "function");
			case TId(id) if(!getValue):
				if(logicOperators.contains(id) || keywords.contains(id)) parseIdent(id);
				else parseNextExpr(parseIdent(id), false, true);
			case TConst(c):
				parseNextExpr(mk(EConst(c)), true, false);
			case TPOpen:
				final oca = commaAnd;
				commaAnd = true;
				var e = parseExpr();
				commaAnd = oca;
				tk = token();
				switch( tk ) {
					case TPClose:
						return parseNextExpr(mk(EParent(e)), false, true);
					case _:
						unexpected(tk, TPClose);
				}
			case TOp("..."):
				parseNextExpr(mk(EConst(CTripleDot)), true, false);
			case TOp(op) if(opPriority.get(op) < 0 || op == "-"):
				if(op == "-") {
					var e = parseExpr();
					if( e == null )
						return makePrefix(op,e);
					switch(e.expr) {
						case EConst(CInt(i)):
							return mk(EConst(CInt(-i)));
						case EConst(CFloat(f)):
							return mk(EConst(CFloat(-f)));
						default:
							return makePrefix(op,e);
					}
				}
				makePrefix(op,parseExpr());
			case TQuadrupleDot if(!getValue):
				var label = getIdent();
				ensure(TQuadrupleDot);
				mk(ELabel(label));
			case TBrOpen:
				parseTable();
			case _:
				unexpected(tk);
		};
	}

	function parseFunctionArgs() {
		var args = new Array<String>();
		var tk = token();
		if( tk == TPClose)
			return args;
		push(tk);
		while( true ) {
			var tb = false;
			args.push(switch(tk = token()) {
				case TId(id): id;
				case TOp("..."):
					tb = true;
					"...";
				case _: unexpected(tk);
			});
			tk = token();
			switch( tk ) {
			case TComma if(!tb):
			default:
				if( tk == TPClose) break;
				unexpected(tk, (tb ? TPClose : TComma));
				break;
			}
		}
		return args;
	}

	function parseExprList( etk) {
		var args = new Array();
		var tk = token();
		if( tk == etk )
			return args;
		push(tk);
		while( true ) {
			// 本来我是想直接解析EAnd来获取arg的，不过想了想算了（
			final oca = commaAnd;
			commaAnd = true;
			args.push(parseExpr(true));
			commaAnd = oca;
			tk = token();
			switch( tk ) {
			case TComma:
			default:
				if( tk == etk ) break;
				unexpected(tk, TComma);
				break;
			}
		}
		return args;
	}

	function parseExprAnds() {
		var args = new Array();
		var tk = null;
		while( true ) {
			tk = token();
			switch( tk ) {
				case TComma:
					args.push(parseExpr(true));
				case TSemicolon:
					push(tk);
					break;
				case TId(id):
					push(tk);
					break;
				case TOp(op):
					push(tk);
					break;
				case TEof:
					push(tk);
					break;
				default:
					unexpected(tk, TComma);
					break;
			}
		}
		return args;
	}

	function mk(e:LuaExprDef, ?line:Int):LuaExpr {
		return {expr: e, line: line ?? this.line};
	}

	function parseIdent(id:String):LuaExpr {
		return switch(id) {
			case "return":
				var t = token();
				push(t);
				if(Type.enumEq(t, TId("until")) || Type.enumEq(t, TId("end")) || t == TSemicolon) {
					return mk(EReturn(null));
				}

				mk(EReturn(parseExpr(true)));
			case "continue":
				mk(EContinue);
			case "break":
				mk(EBreak);
			case "local":
				var t = token();
				switch(t) {
					case TId(id) if(!logicOperators.contains(id) && !keywords.contains(id)):
						var idents = [id];
						while( true ) {
							var tk = token();
							switch( tk ) {
								case TComma:
									idents.push(getIdent());
								case TEof, TSemicolon:
									push(tk);
									break;
								case TId(id):
									push(tk);
									break;
								case TOp(op):
									push(tk);
									break;
								default:
									unexpected(tk, TOp("="));
									break;
							}
						}
						if(idents.length > 1) mk(ELocal(parseNextExpr(mk(EAnd([for(id in idents) mk(EIdent(id))])))));
						else mk(ELocal(parseNextExpr(mk(EIdent(idents[0])))));
					case TId("function"):
						push(t);
						mk(ELocal(parseExpr()));
					case _:
						unexpected(t);
				}
			case "if":
				var cond = parseExpr();
				var eelseif = [];
				var eelse:Null<LuaExpr> = null;
				ensure(TId("then"));
				var body = parseTd(["elseif", "else"]);

				function ik(eif:Array<LuaElseIf>) {
					var t = token();
					switch(t) {
						case TId("elseif"):
							var cond = parseExpr();
							ensure(TId("then"));
							var ee = parseTd(["elseif", "else"]);
							eif.push({cond: cond, body: ee});
							ik(eif);
						case TId("else"):
							eelse = parseTd(["elseif", "else"]);
							var t = token();
							switch(t) {
								case TId("end"):
								case _: unexpected(t, TId("end"));
							}
						case TId("end"):
						case _:
							unexpected(t, TId("end"));
					}
				}
				ik(eelseif);
				mk(EIf(cond, body, eelseif, eelse));
			case "do":
				parseTd(false, true, true);
			case "for":
				var v = getIdent();
				if(maybe(TOp("="))) {
					final oca = commaAnd;
					commaAnd = true;
					var start = parseExpr();
					ensure(TComma);
					var end = parseExpr();
					var step = null;
					if(maybe(TComma)) {
						step = parseExpr();
					}
					commaAnd = oca;
					ensure(TId("do"));
					var body = parseTd(false);
					mk(EForNum(v, body, start, end, step));
				} else {
					var k:Null<String> = null;
					if(maybe(TComma)) {
						k = v;
						v = getIdent();
					}

					ensure(TId("in"));
					var iterator_func = parseExpr();
					ensure(TId("do"));
					var body = parseTd(false);
					if(k == null) mk(EForGen(body, iterator_func, v));
					else mk(EForGen(body, iterator_func, k, v));
				}
			case "repeat":
				var body = parseTd(["until"], false, false);
				final oca = commaAnd;
				commaAnd = true;
				var cond = parseExpr();
				commaAnd = oca;
				mk(ERepeat(body, cond));
			case "while":
				var cond = parseExpr();
				ensure(TId("do"));
				var body = parseTd(false);
				mk(EWhile(cond, body));
			case "function":
				var isDouble:Bool = false;
				function ik(ae) {
					var t = token();
					switch(t) {
						case TDot:
							ae.push(getIdent());
							ik(ae);
						case TDoubleDot:
							ae.push(getIdent());
							t = token();
							if(t != TPOpen) unexpected(t, TPOpen);
							push(t);
							isDouble = true;
							ik(ae);
						case TPOpen:
						case _:
							unexpected(t);
					}
				}
				var names = [];
				var t = token();
				switch(t) {
					case TId(id) if(logicOperators.contains(id) || keywords.contains(id)):
						unexpected(t);
					case TPOpen:
					case _:
						if(t != TEof) {
							push(t);
							names.push(getIdent());
							ik(names);
						}
				}
				var args = parseFunctionArgs();
				final ca = commaAnd;
				commaAnd = false;
				final oaq = assignQuare;
				assignQuare = false;
				final oldInObject = inObject;
				inObject = false;
				final body = parseTd(false);
				inObject = oldInObject;
				assignQuare = oaq;
				commaAnd = ca;
				mk(EFunction(args, body, {names: names, isDouble: isDouble}));
			case _ if(!keywords.contains(id) && !logicOperators.contains(id)):
				mk(EIdent(id));
			default:
				error(ECustom("Cannot use \"" + id + "\", Its Keyword"));
		}
	}

	function parseTd(?utils:Array<String>, ?fudai:Bool = true, ?cEnd:Bool = true, ?isBlock:Bool = false):LuaExpr {
		utils = utils ?? [];
		var ae:Array<LuaExpr> = [];
		while(true) {
			var t = token();
			var cond:Bool = {
				var pre = false;
				for(util in utils) {
					if(Type.enumEq(t, TId(util))) pre = true;
				}
				pre;
			};
			if(cond || (cEnd && Type.enumEq(t, TId("end"))) || t == TEof) {
				if(t == TEof) unexpected(t, TId("end"));
				if(fudai) push(t);
				break;
			}
			push(t);

			parseFullExpr(ae);
		}
		return mk(ETd(ae, isBlock));
	}

	function parseTable() {
		var kvs = [];

		var t = null;
		while((t = token()) != TBrClose) {
			push(t);
			var kv = {key: null, v: null, haveBK: false, endSemicolon: false};
			if(maybe(TBkOpen)) {
				kv.haveBK = true;
				final oio = inObject;
				inObject = true;
				kv.key = parseExpr();
				inObject = oio;
				ensure(TBkClose);
				ensure(TOp("="));

				final oio = inObject;
				inObject = true;
				kv.v = parseExpr();
				inObject = oio;
			} else {
				final oio = inObject;
				inObject = true;
				var e = parseExpr();
				if(maybe(TOp("=")) && e.expr.match(EIdent(_))) {
					kv.key = e;
					kv.v = parseExpr();
				} else {
					kv.v = e;
				}
				inObject = oio;
			}

			var t = token();
			switch(t) {
				case TComma:
				case TSemicolon:
					kv.endSemicolon = true;
				case TBrClose:
					push(t);
				case _:
					unexpected(t);
			}

			kvs.push(kv);
		}

		return mk(ETable(kvs));
	}

	function unexpected(t:LuaToken, ?ext:LuaToken):Dynamic {
		return error(EUnexpected(tokenString(t), (ext != null ? tokenString(ext) : null)));
	}

	function error(err:LuaErrorDef, ?line:Int):Dynamic {
		throw new LuaError(err, line ?? this.line);
		return null;
	}

	function readString(until:Int):String {
		var c = 0;
		var b = new StringBuf();
		var esc = false;
		while( true ) {
			c = readPos();
			if( StringTools.isEof(c) || c == 10 || c == "\r".code) {
				error(EUnterminatedString(c));
				break;
			}
			if( esc ) {
				esc = false;
				switch( c ) {
					case "a".code:
					case "b".code:
					case "f".code:
					case "v".code:
					case _ if(inNumber(c)):
						var s = String.fromCharCode(c);
						for(i in 0...2) {
							if(inNumber(c = readPos())) {
								s += String.fromCharCode(c);
							} else {
								pos--;
								break;
							}
						}
						b.addChar(Std.parseInt(s));
					case "x".code:
					case 'n'.code: b.addChar('\n'.code);
					case 'r'.code: b.addChar('\r'.code);
					case 't'.code: b.addChar('\t'.code);
					case "'".code, '"'.code, '\\'.code: b.addChar(c);
					default: error(EUnterminatedString(c));
				}
			} else if( c == 92 )
				esc = true;
			else if( c == until )
				break;
			else {
				b.addChar(c);
			}
		}
		return b.toString();
	}

	function niubierlyReadString(i:Int = 0) {
		var buf = new StringBuf();
		var c = 0;
		while(true) {
			c = readPos();
			if(StringTools.isEof(c)) {
				error(EUnterminatedString(c));
				break;
			}
			if(c == 10) line++;
			if(c == "]".code) {
				var nd = readPos();
				if(nd == "=".code && i > 0) {
					var cond = true;
					final old = pos;
					for(i in 0...i) {
						if(nd != "=".code) {
							cond = false;
							break;
						}
						nd = readPos();
					}
					if(cond && nd == "]".code) break;
					pos = old;
				} else if(nd == "]".code) {
					break;
				}
				pos--;
			}
			buf.addChar(c);
		}
		return buf.toString();
	}

	inline function readPos():Int {
		return StringTools.fastCodeAt(content, pos++);
	}

	inline function push(t:LuaToken):Void {
		_tokens.add(t);
	}

	inline function ensure(tk) {
		var t = token();
		if( !Type.enumEq(t, tk) ) unexpected(t, tk);
	}

	function maybe(tk) {
		var t = token();
		if( Type.enumEq(t, tk) )
			return true;
		push(t);
		return false;
	}

	function token():LuaToken {
		if(!_tokens.isEmpty())
			return _tokens.pop();

		var char = readPos();
		_token = switch(char) {
			case "\"".code:
				TConst(CString(readString("\"".code), DoubleQuotes));
			case "=".code:
				char = readPos();
				if(char == "=".code) {
					TOp("==");
				} else {
					pos--;
					TOp("=");
				}
			case "+".code, "*".code, "%".code, "^".code, "#".code:
				TOp(String.fromCharCode(char));
			case "-".code:
				char = readPos();
				if(char == "-".code) {
					final old = pos;
					char = readPos();
					if(char == "[".code) {
						char = readPos();
						if(char == "=".code) {
							var i = 1;
							while((char = readPos()) == "=".code) {
								i++;
							}
							if(char == "[".code) {
								pos = old;
								return sayComment(i);
							}
						}
					}
					pos = old;
					sayComment();
				} else {
					pos--;
					TOp("-");
				}
			case "/".code:
				char = readPos();
				if(char == "/".code) {
					TOp("//");
				} else {
					pos--;
					TOp("/");
				}
			case "~".code:
				char = readPos();
				if(char == "=".code) {
					TOp("~=");
				} else {
					error(EUnexpected(String.fromCharCode(char), "="));
				}
			case ">".code:
				char = readPos();
				if(char == "=".code) {
					TOp(">=");
				} else {
					pos--;
					TOp(">");
				}
			case "<".code:
				char = readPos();
				if(char == "=".code) {
					TOp("<=");
				} else {
					pos--;
					TOp("<");
				}
			case ".".code:
				char = readPos();
				if(inNumber(char)) {
					var buf = new StringBuf();
					var exp = false;
					buf.add(".");
					buf.addChar(char);
					while(true) {
						if(!inNumber(char = readPos())) {
							if(!exp && (char == "e".code || char == "E".code)) {
								exp = true;
								var prefix = false;
								var number = false;
								buf.addChar(char);
								while(true) {
									switch(char = readPos()) {
										case "+".code, "-".code if(!prefix):
											prefix = true;
											buf.addChar(char);
										case _ if(inNumber(char)):
											number = true;
											buf.addChar(char);
										case _:
											if(!number || inLetter(char) || char == ".".code) {
												error(EInvalidChar(char));
											}
											pos--;
											break;
									}
								}
								continue;
							}
							if(inLetter(char) || inDownLine(char) || char == ".".code) {
								error(EUnexpected(String.fromCharCode(char)));
							}
							pos--;
							break;
						}
						buf.addChar(char);
					}
					TConst(CFloat(Std.parseFloat(buf.toString())));
				} else if(char == ".".code) {
					if((char = readPos()) == ".".code) {
						TOp("...");
					} else {
						pos--;
						TOp("..");
					}
				} else {
					pos--;
					TDot;
				}
			case ",".code:
				TComma;
			case ";".code:
				TSemicolon;
			case "'".code:
				TConst(CString(readString("'".code), SingleQuotes));
			case ":".code:
				char = readPos();
				if(char == ":".code) {
					TQuadrupleDot;
				} else {
					pos--;
					TDoubleDot;
				}
			case "{".code:
				TBrOpen;
			case "}".code:
				TBrClose;
			case "[".code:
				char = readPos();
				if(char == "=".code) {
					var i = 1;
					while((char = readPos()) == "=".code) {
						i++;
					}
					if(char == "[".code) {
						return TConst(CString(niubierlyReadString(i), SquareBracket(i)));
					} else pos -= i;
				} else if(char == "[".code) return TConst(CString(niubierlyReadString(), SquareBracket(0)));
				pos--;
				TBkOpen;
			case "]".code:
				TBkClose;
			case "(".code:
				TPOpen;
			case ")".code:
				TPClose;
			case 10:
				line++;
				token();
			case 9, 32, 13:
				token();
			case _ if(StringTools.isEof(char)):
				TEof;
			case _ if(inLetter(char)):
				var id:String = String.fromCharCode(char);
				while(true) {
					if(!inLu(char = readPos())) {
						pos--;
						break;
					}
					id += String.fromCharCode(char);
				}
				if(logicOperators.contains(id)) TOp(id);
				else TId(id);
			case _ if(inNumber(char)):
				var buf = new StringBuf();
				buf.addChar(char);
				var sureStartSex = if(char == "0".code) {
					var nc = readPos();
					if(nc == "x".code || nc == "X".code) {
						buf.addChar(nc);
						true;
					} else {
						pos--;
						false;
					}
				} else false;
				var isFloat = false;
				var exp = false;
				while(true) {
					if(sureStartSex) {
						if(!inSex(char = readPos()) && (isFloat || char != ".".code)) {
							if(inLetter(char) || char == ".".code) {
								error(EInvalidChar(char));
							}
							pos--;
							break;
						}
						if(!isFloat && char == ".".code) isFloat = true;
						buf.addChar(char);
					} else {
						if(!inNumber(char = readPos()) && (isFloat || char != ".".code)) {
							if(!exp && (char == "e".code || char == "E".code)) {
								exp = true;
								var prefix = false;
								var number = false;
								buf.addChar(char);
								while(true) {
									switch(char = readPos()) {
										case "+".code, "-".code if(!prefix):
											prefix = true;
											buf.addChar(char);
										case _ if(inNumber(char)):
											number = true;
											buf.addChar(char);
										case _:
											if(!number || inLetter(char) || char == ".".code) {
												error(EInvalidChar(char));
											}
											pos--;
											break;
									}
								}
								continue;
							}
							if(inLetter(char) || char == ".".code) {
								error(EInvalidChar(char));
							}
							pos--;
							break;
						}
						if(!isFloat && char == ".".code) isFloat = true;
						buf.addChar(char);
					}
				}
				TConst(if(isFloat || exp) CFloat(Std.parseFloat(buf.toString())) else CInt(Std.parseInt(buf.toString())));
			default:
				error(EInvalidChar(char));
		}
		return _token;
	}

	function sayComment(i:Int = 0):LuaToken {
		var char = readPos();
		var char1 = readPos();
		if(i == 0 && (char != "[".code || char1 != "[".code)) {
			pos -= 2;
			while(true) {
				if((char = readPos()) == 10 || char == "\r".code || StringTools.isEof(char)) {
					pos--;
					break;
				}
			}
		} else {
			while(true) {
				char = readPos();
				if(char == "]".code) {
					var nd = readPos();
					if(i > 0) {
						var cond = true;
						final old = pos;
						for(i in 0...i) {
							if(nd != "=".code) {
								cond = false;
								break;
							}
							nd = readPos();
						}
						if(cond && nd == "]".code) break;
						pos = old;
					} else if(nd == "]".code) {
						break;
					}
					pos--;
				}
				if(StringTools.isEof(char)) {
					error(EUnterminatedComment);
					break;
				}
				if(char == 10) {
					line++;
				}
			}
		}
		return token();
	}

	inline static function inLetter(char:Int):Bool {
		return (char >= 65 && char <= 90) || (char >= 97 && char <= 122) || inDownLine(char);
	}

	inline static function inNumber(char:Int):Bool {
		return char >= 48 && char <= 57;
	}

	inline static function inDownLine(char:Int):Bool {
		return char == 95;
	}

	public inline static function inLu(char:Int):Bool {
		return inNumber(char) || inLetter(char);
	}

	inline static function inSex(char:Int):Bool {
		return inNumber(char) || (char >= 97 && char <= 102) || (char >= 65 && char <= 70);
	}

	inline static function constString(c:LuaConst):String {
		return switch(c) {
			case CInt(v): Std.string(v);
			case CFloat(f): Std.string(f);
			case CString(s, k): switch(k) {
				case DoubleQuotes: '"' + s + '"';
				case SingleQuotes: "'" + s + '"';
				case SquareBracket(count):
					var eqbuf = new StringBuf();
					for(i in 0...count) eqbuf.add("=");
					final r = eqbuf.toString();
					"[" + r + "[" + s + "]" + r + "]";
			};
			case CTripleDot: "...";
		}
	}

	inline static function tokenString(t:LuaToken):String {
		return switch(t) {
		case TEof: "<eof>";
		case TConst(c): constString(c);
		case TId(s): s;
		case TOp(s): s;
		case TPOpen: "(";
		case TPClose: ")";
		case TBrOpen: "{";
		case TBrClose: "}";
		case TDot: ".";
		case TComma: ",";
		case TSemicolon: ";";
		case TBkOpen: "[";
		case TBkClose: "]";
		case TDoubleDot: ":";
		case TQuadrupleDot: "::";
		}
	}
}
