package luahscript;

import luahscript.exprs.LuaExpr;
import luahscript.exprs.LuaError;
import luahscript.exprs.LuaToken;
import luahscript.exprs.*;
import haxe.Constraints.IMap;

typedef LuaLocalVar = {
	var r: Dynamic;
}

typedef LuaDeclaredVar = {
	var n:String;
	var old:Dynamic;
}

class LuaInterp {
	public var globals:Map<String, Dynamic>;

	private var locals:Map<String, LuaLocalVar>;
	private var declared:Array<LuaDeclaredVar>;

	private var markedLabels:Map<String, Array<LuaExpr>>;
	private var mlLabelsRecord:Array<{var n:String; var old:Array<LuaExpr>;}>;

	var binops:Map<String, Dynamic->Dynamic->Dynamic>;

	var curExpr:LuaExpr;
	var return_value:LuaAndParams;
	var throw_label:String;
	var triple_value:LuaAndParams;

	public function new() {
		var me = this;
		binops = new Map();
		/**
			["^"],
			["not", "#"],
			["*", "/", "//", "%"],
			["+", "-"],
			[".."],
			["<", ">", "<=", ">=", "~=", "=="],
			["and"],
			["or"],
			["="],
		*/
		binops.set("^", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__pow")) return cast(a, LuaTable<Dynamic>).__pow(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			return Math.pow(a, b);
		});
		binops.set("*", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__mul")) return cast(a, LuaTable<Dynamic>).__mul(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			return a * b;
		});
		binops.set("/", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__div")) return cast(a, LuaTable<Dynamic>).__div(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			return a / b;
		});
		binops.set("//", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__idiv")) return cast(a, LuaTable<Dynamic>).__idiv(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			final result = a / b;
			return if(result >= 0) Math.floor(result);
			else Math.ceil(result);
		});
		binops.set("%", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__mod")) return cast(a, LuaTable<Dynamic>).__mod(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			return a % b;
		});
		binops.set("+", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__add")) return cast(a, LuaTable<Dynamic>).__add(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			return a + b;
		});
		binops.set("-", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__sub")) return cast(a, LuaTable<Dynamic>).__sub(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			return a - b;
		});
		binops.set("..", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__concat")) return cast(a, LuaTable<Dynamic>).__concat(a, b);
			return Std.string(LuaCheckType.checkNotSpecialValue(a)) + Std.string(LuaCheckType.checkNotSpecialValue(b));
		});
		binops.set("<", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__lt")) return cast(a, LuaTable<Dynamic>).__lt(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER) {
				a = Lua_tonumber.tonumber(a);
				if(a == null || Math.isNaN(a)) throw "invalid reading number";
			}
			if(LuaCheckType.checkType(b) != TNUMBER) {
				b = Lua_tonumber.tonumber(b);
				if(b == null || Math.isNaN(b)) throw "invalid reading number";
			}
			return a < b;
		});
		binops.set(">", function(a:Dynamic, b:Dynamic) {
			if(LuaCheckType.checkType(a) != TNUMBER || LuaCheckType.checkType(b) != TNUMBER) throw "invalid reading number";
			return a > b;
		});
		binops.set("<=", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__le")) return cast(a, LuaTable<Dynamic>).__le(a, b);
			if(LuaCheckType.checkType(a) != TNUMBER || LuaCheckType.checkType(b) != TNUMBER) throw "invalid reading number";
			return a <= b;
		});
		binops.set(">=", function(a:Dynamic, b:Dynamic) {
			if(LuaCheckType.checkType(a) != TNUMBER || LuaCheckType.checkType(b) != TNUMBER) throw "invalid reading number";
			return a >= b;
		});
		binops.set("~=", function(a:Dynamic, b:Dynamic) {
			return a != b;
		});
		binops.set("==", function(a:Dynamic, b:Dynamic) {
			if(isMetaTable(a) && a.metaTable.keyExists("__eq")) return cast(a, LuaTable<Dynamic>).__eq(a, b);
			return a == b;
		});
		binops.set("and", function(a:Dynamic, b:Dynamic) {
			if(!LuaTools.luaBool(a)) return a;
			return b;
		});
		binops.set("or", function(a:Dynamic, b:Dynamic) {
			if(LuaTools.luaBool(a)) return a;
			return b;
		});

		globals = new Map();
		globals.set("print", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var buf = new StringBuf();
			for(i=>arg in args) {
				buf.add(Std.string(arg));
				if(i < args.length - 1) buf.add("\t");
			}
			#if js
			if (js.Syntax.typeof(untyped console) != "undefined" && (untyped console).log != null)
				(untyped console).log(buf.toString());
			#elseif lua
			untyped __define_feature__("use._hx_print", _hx_print(buf.toString()));
			#elseif sys
			Sys.println(buf.toString());
			#else
			throw new haxe.exceptions.NotImplementedException()
			#end
		}));
		globals.set("type", function(v:Dynamic):String {
			return LuaCheckType.checkType(v);
		});
		globals.set("tostring", function(v:Dynamic):String {
			return Std.string(v);
		});
		globals.set("tonumber", function(v:Dynamic, ?base:Int) {
			return Lua_tonumber.tonumber(v, base);
		});
		globals.set("assert", function(v:Dynamic, ?message:String) {
			if(LuaTools.luaBool(v)) return v;
			throw message;
			return null;
		});
		globals.set("error", luastd_error);
		globals.set("pcall", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			if(args.length > 0) {
				var func:Dynamic = null;
				if(LuaCheckType.checkType(func = args.shift()) == TFUNCTION) {
					try {
						final result = Reflect.callMethod(null, func, args);
						if(isAndParams(result)) {
							return LuaAndParams.fromArray([true].concat(result.values));
						} else {
							return LuaAndParams.fromArray([true, result]);
						}
					} catch(e) {
						return LuaAndParams.fromArray([false, Std.string(e)]);
					}
				}
				return LuaAndParams.fromArray([false, "attempt call a nil value"]);
			}
			throw "bad argument #1 to pcall";
			return null;
		}));
		globals.set("select", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			if(args.length > 0) {
				var v = args.shift();
				if(LuaCheckType.isInteger(v)) {
					final i:Int = cast v;
					if(i > 0) {
						while(args.length > i) {
							args.shift();
						}
						return LuaAndParams.fromArray(args);
					}
				} else if(v == "#") {
					return LuaAndParams.fromArray([args.length]);
				}
			}
			throw "bad argument #1 to select";
			return null;
		}));
		globals.set("rawequal", function(v1:Dynamic, v2:Dynamic):Bool {
			return v1 == v2;
		});
		globals.set("rawget", function(table:LuaTable<Dynamic>, key:Dynamic, value:Dynamic) {
			return LuaCheckType.checkTable(table).get(key);
		});
		globals.set("rawset", function(table:LuaTable<Dynamic>, key:Dynamic, value:Dynamic) {
			return LuaCheckType.checkTable(table).set(key, value);
		});
		globals.set("rawlen", function(v:Dynamic):Null<Int> {
			if(v.length != null && LuaCheckType.isInteger(v.length)) return v.length;
			return null;
		});
		globals.set("next", luastd_next);
		globals.set("pairs", luastd_pairs);
		globals.set("ipairs", function(it:Dynamic):LuaAndParams {
			return LuaAndParams.fromArray([ipairs_fu, it, 0]);
		});
		globals.set("setmetatable", function(o:LuaTable<Dynamic>, meta:LuaTable<Dynamic>):LuaTable<Dynamic> {
			LuaCheckType.checkTable(o).metaTable = LuaCheckType.checkTable(meta);
			return o;
		});
		globals.set("getmetatable", function(o:LuaTable<Dynamic>):LuaTable<Dynamic> {
			return LuaCheckType.checkTable(o).metaTable;
		});
		setDownlineG();

		initLuaLibs(globals);
	}

	private inline function setDownlineG() {
		var table:LuaTable<Dynamic> = new LuaTable();
		var meta:LuaTable<Dynamic> = new LuaTable();
		meta.set("__index", function(table:LuaTable<Dynamic>, n:Dynamic) {
			return globals.get(n);
		}, false);
		meta.set("__newindex", function(table:LuaTable<Dynamic>, n:Dynamic, value:Dynamic) {
			return globals.set(n, value);
		}, false);
		table.metaTable = meta;
		this.globals.set("_G", table);
	}

	private static var lualibs = new Map<String, LuaTable<Dynamic>>();
	public static function initLuaLibs(map:Map<String, Dynamic>) {
		// fw lua lib
		setLibs(map, "math", luahscript.lualibs.LuaMathLib);
		setLibs(map, "string", luahscript.lualibs.LuaStringLib);
		setLibs(map, "table", luahscript.lualibs.LuaTableLib);
		setLibs(map, "os", luahscript.lualibs.LuaOSLib);
		#if sys
		setLibs(map, "io", luahscript.lualibs.LuaIOLib);
		#end
	}

	private static function setLibs(map:Map<String, Dynamic>, name:String, value:Dynamic) {
		value = if(lualibs.exists(name)) {
			lualibs.get(name);
		} else {
			final v:Dynamic = value.implement();
			lualibs.set(name, v);
			v;
		}
		map.set(name, value);
	}

	public function execute(expr:LuaExpr):Dynamic {
		locals = new Map();
		markedLabels = new Map();
		mlLabelsRecord = new Array();
		declared = new Array();
		return this.expr(expr);
	}

	function exprReturn(e:LuaExpr):LuaAndParams {
		try {
			expr(e);
		} catch(s:LuaStop) {
			switch (s) {
				case SBreak:
					throw "break outside loop";
				case SContinue:
					throw "continue outside loop";
				case SReturn:
					if(return_value != null) return return_value;
				case SLabel: //Im not sure it will hanppen.
			}
		}
		return new LuaAndParams();
	}

	function expr(e:LuaExpr, isLocal:Bool = false):Dynamic {
		this.curExpr = e;
		switch(e.expr) {
			case EConst(c):
				switch(c) {
					case CInt(sb): return sb;
					case CFloat(sb): return sb;
					case CString(sb, _): return sb;
					case CTripleDot: return triple_value;
				}
			case EIdent(id):
				return switch(id) {
					case "true": true;
					case "false": false;
					case "nil": null;
					case _: resolve(id);
				}
			case EParent(e):
				return expr(e);
			case EField(e, f, isDouble):
				var obj:Dynamic = getParamsFirst(expr(e));
				if(obj == null) {
					var sb:Null<String> = null;
					var type:Null<LuaVariableType> = null;
					LuaTools.recursion(e, function(e:LuaExpr) {
						switch(e.expr) {
							case EIdent(id):
								sb = id;
								type = if(locals.get(id) != null) LOCAL; else GLOBAL;
							case EField(_, f):
								sb = f;
								type = FIELD;
							case EArray(_, _):
								sb = 'integer index';
								type = FIELD;
							default:
								type = UNKNOWN;
						}
					});
					error(EInvalidAccess(sb, type));
				}

				return get(obj, f, isDouble);
			case ELocal(e):
				return expr(e, true);
			case EBinop(op, e1, e2):
				if(op == "=") {
					evalAssignOp(e1, e2, isLocal);
					return null;
				}
				final left:Dynamic = getParamsFirst(expr(e1));
				final right:Dynamic = getParamsFirst(expr(e2));
				var fop = binops.get(op);
				if(fop != null) return fop(left, right);
				return error(EInvalidOp(op));
			case EPrefix(prefix, e):
				var v:Dynamic = getParamsFirst(expr(e));
				return switch(prefix) {
					case "#":
						if(isMetaTable(v) && v.metaTable.keyExists("__len")) return cast(v, LuaTable<Dynamic>).__len(v);
						else if(isTable(v)) @:privateAccess return cast(v, LuaTable<Dynamic>).nextIndex - 1;
						if(v.length != null) v.length else 0;
					case "not":
						!LuaTools.luaBool(v);
					case "-":
						if(isMetaTable(v) && v.metaTable.keyExists("__unm")) return cast(v, LuaTable<Dynamic>).__unm(v);
						-LuaCheckType.checkNumber(v);
					case _:
						error(EInvalidOp(prefix));
				}
			case ECall(e, params):
				final args:Array<Dynamic> = [];
				for(i=>p in params) {
					var v:Dynamic = expr(p);
					if(isAndParams(v)) {
						final lap:LuaAndParams = cast v;
						if(lap.values.length > 0) {
							for(value in lap.values) {
								args.push(value);
							}
						}
						continue;
					}
					args.push(v);
				}

				switch(e.expr) {
					case EField(ef, f, isDouble): // Handles obj:method() and obj.method()
						var obj:Dynamic = getParamsFirst(expr(ef));
						if(obj == null) {
							var sb:Null<String> = null;
							var type:Null<LuaVariableType> = null;
							LuaTools.recursion(ef, function(e:LuaExpr) {
								switch(e.expr) {
									case EIdent(id):
										sb = id;
										type = if(locals.get(id) != null) LOCAL; else GLOBAL;
									case EField(_, f):
										sb = f;
										type = FIELD;
									case EArray(_, _):
										sb = 'integer index';
										type = FIELD;
									default:
										type = UNKNOWN;
								}
							});
							error(EInvalidAccess(sb, type));
						}

						final func:Dynamic = get(obj, f, isDouble);
						if(func == null) {
							var sb:Null<String> = null;
							var type:Null<LuaVariableType> = null;
							LuaTools.recursion(e, function(e:LuaExpr) {
								switch(e.expr) {
									case EIdent(id):
										sb = id;
										type = if(locals.get(id) != null) LOCAL; else GLOBAL;
									case EField(_, f_name): 
										sb = f_name;
										type = FIELD;
									case EArray(_, _):
										sb = 'integer index';
										type = FIELD;
									default:
										type = UNKNOWN;
								}
							});
							error(ECallNilValue(sb, type));
						}
						if (isDouble) args.insert(0, obj);
						return Reflect.callMethod(null, func, args);
					case _:
						var func:Dynamic = getParamsFirst(expr(e));
						if(func == null) {
							var sb:Null<String> = null;
							var type:Null<LuaVariableType> = null;
							LuaTools.recursion(e, function(e:LuaExpr) {
								switch(e.expr) {
									case EIdent(id):
										sb = id;
										type = if(locals.get(id) != null) LOCAL; else GLOBAL;
									case EField(_, f):
										sb = f;
										type = FIELD;
									case EArray(_, _):
										sb = 'integer index';
										type = FIELD;
									default:
										type = UNKNOWN;
								}
							});
							error(ECallNilValue(sb, type));
						}
						return Reflect.callMethod(null, func, args);
				}
			case ETd(ae):
				var old = declared.length;
				final oldLabels = mlLabelsRecord.length;
				var labels = [];
				Lambda.iter(ae, function(e) {
					switch(e.expr) {
						case ELabel(id):
							mlLabelsRecord.push({n: id, old: markedLabels.get(id)});
							markedLabels.set(id, []);
							labels.push(id);
						case _:
							for(label in labels) {
								final arr = markedLabels.get(label);
								if(arr != null) {
									arr.push(e);
								}
							}
					}
				});
				try {
					for(e in ae) {
						expr(e);
					}
				} catch(e:LuaStop) {
					switch(e) {
						case SLabel if(throw_label != null && labels.contains(throw_label)):
							throw_label = null;
						case _: throw e;
					}
				}
				restoreLabels(oldLabels);
				restore(old);
			case EAnd(sb):
				var ae = new LuaAndParams();
				for(e in sb) {
					var v:Dynamic = expr(e);
					if(isAndParams(v)) ae.concat(v);
					else ae.push(v);
				}
				return ae;
			case EIf(cond, body, eis, eel):
				final newCond = expr(cond);
				if(LuaTools.luaBool(newCond)) {
					expr(body);
				} else {
					var crosseis = false;
					if(eis != null) for(e in eis) {
						final newCond = expr(e.cond);
						if(LuaTools.luaBool(newCond)) {
							crosseis = true;
							expr(e.body);
							break;
						}
					}
					if(!crosseis && eel != null) {
						expr(eel);
					}
				}
			case ERepeat(body, cond):
				var newCond:Dynamic = null;
				do {
					if(!loopRun(() -> expr(body)))
						break;
				} while((newCond = expr(cond)) == false || newCond == null);
			case EWhile(cond, e):
				while(LuaTools.luaBool(expr(cond))) {
					if(!loopRun(() -> expr(e)))
						break;
				}
			case EForNum(v, body, start, end, step):
				var old = declared.length;
				declared.push({ n : v, old : locals.get(v) });
				var start:Float = expr(start);
				var end:Float = expr(end);
				var step:Null<Float> = (step != null ? expr(step) : null);
				final it = new LuaNumIterator(start, end, step);
				for(i in it) {
					locals.set(v, {r: i});
					if(!loopRun(() -> expr(body)))
						break;
				}
				restore(old);
			case EForGen(body, iterator, k, v):
				forGenLoop(k, v, iterator, body);
			case EBreak:
				throw LuaStop.SBreak;
			case EContinue:
				throw LuaStop.SContinue;
			case EFunction(args, e, info):
				var index = args.indexOf("...");
				final names = (info != null ? info.names : []);
				var me = this;
				var isDouble = false;
				var obj:Dynamic = null;
				if(info != null) {
					isDouble = info.isDouble;
					var preName:Null<String> = null;
					if(names.length > 1) for(i=>name in names) {
						if(i == 0) {
							obj = resolve(name);
						} else {
							if(obj == null) error(EInvalidAccess(preName, (preName == null ? UNKNOWN : (i > 1 ? FIELD : (locals.get(preName) != null ? LOCAL : GLOBAL)))));
							if(i < names.length - 1) obj = get(obj, name, isDouble);
						}
						preName = name;
					}
					if(isDouble && isLocal) error(ECustom("Cannot define the field of a global variable as local"));
				}
				if(isDouble) args.insert(0, "self");
				var capturedLocals = duplicate(locals);
				var f = Reflect.makeVarArgs(function(params:Array<Dynamic>) {
					var old = me.locals;
					var oldDecl = me.declared.length;
					me.locals = me.duplicate(capturedLocals);
					final tv = me.triple_value;
					for(i=>arg in args) {
						if(arg == "...") {
							me.triple_value = LuaAndParams.fromArray(params);
							break;
						} else {
							me.declared.push({ n : arg, old : locals.get(arg) });
							me.locals.set(arg, {r: params.shift()});
						}
					}
					var oldDecl = declared.length;
					var r = me.exprReturn(e);
					restore(oldDecl);
					me.locals = old;
					me.triple_value = tv;
					return r;
				});
				if(names.length > 0) {
					final name = names[names.length - 1];
					if(obj != null) {
						if(isTable(obj)) cast(obj, LuaTable<Dynamic>).set(name, f);
						else error(ECustom("not support loading functions in object forms other than tables"));
					} else {
						if(isLocal) {
							declared.push({n: name, old: locals.get(name)});
							locals.set(name, {r: f});
						} else {
							globals.set(name, f);
						}
					}
				}
				return f;
			case EGoto(label):
				if(markedLabels.get(label) == null) error(ECustom("no visible label '" + label + "' for <goto>"));
				for(e in markedLabels.get(label)) {
					expr(e);
				}
				throw_label = label;
				throw LuaStop.SLabel;
			case EIgnore, ELabel(_):
			case EReturn(e):
				var v:Dynamic = (e == null ? null : expr(e));
				if(!isAndParams(v)) {
					return_value = LuaAndParams.fromArray([v]);
				} else {
					return_value = v;
				}
				throw LuaStop.SReturn;
			case EArray(e, index):
				var o:Dynamic = getParamsFirst(expr(e));
				if(o == null) {
					var sb:Null<String> = null;
					var type:Null<LuaVariableType> = null;
					LuaTools.recursion(e, function(e:LuaExpr) {
						switch(e.expr) {
							case EIdent(id):
								sb = id;
								type = if(locals.get(id) != null) LOCAL; else GLOBAL;
							case EField(_, f):
								sb = f;
								type = FIELD;
							case EArray(_, _):
								sb = 'integer index';
								type = FIELD;
							default:
								type = UNKNOWN;
						}
					});
					error(EInvalidAccess(sb, type));
				}
				if(isTable(o)) return cast(o, LuaTable<Dynamic>).__read(o, expr(index));
				return o[getParamsFirst(expr(index))];
			case ETable(fls):
				var table = new LuaTable<Dynamic>();
				var i = 0;
				for(fl in fls) {
					var value = expr(fl.v);
					if(isAndParams(value) && fl.key == null) {
						for(i=>v in cast(value, LuaAndParams).values) {
							table.set(i + 1, v);
						}
						break;
					}
					value = getParamsFirst(value);
					if(fl.key != null) {
						var key:Dynamic = switch(fl.key.expr) {
							case EIdent(id) if(fl.haveBK != true): 
								curExpr = fl.key;
								id;
							case _:
								getParamsFirst(expr(fl.key));
						}
						if(key == null) error(ECustom("table index is nil"));
						table.set(key, value, false);
					} else {
						i++;
						table.set(i, value, false);
					}
				}
				return table;
		}

		return null;
	}

	public function resolve(id:String):Dynamic {
		final l = locals.get(id);
		if(l != null) {
			return l.r;
		}

		if(globals.exists(id)) {
			return globals.get(id);
		}
		return null;
	}

	function get(obj:Dynamic, f:String, isDouble:Bool = false):Dynamic {
		if(obj is String) {
			if(isDouble && lualibs.exists("string")) {
				return lualibs.get("string").get(f);
			}
			return null;
		}
		if(isTable(obj)) {
			final result = cast(obj, LuaTable<Dynamic>).__read(obj, f);
			return result;
		}
		return Reflect.getProperty(obj, f);
	}

	function set(obj:Dynamic, f:String, value:Dynamic, isDouble:Bool = false) {
		if(isTable(obj)) return cast(obj, LuaTable<Dynamic>).__write(obj, f, value);
		Reflect.setProperty(obj, f, value);
	}

	function evalAssignOpExpr(e1:LuaExpr, e2:Dynamic, isLocal:Bool = false) {
		switch(e1.expr) {
			case EIdent(id):
				var ex:Array<Dynamic> = if(isAndParams(e2)) cast(e2, LuaAndParams).values; else [e2];
				if(isLocal) {
					declared.push({n: id, old: locals.get(id)});
					locals.set(id, {r: ex[0]});
				} else {
					if(locals.get(id) == null) {
						globals.set(id, ex[0]);
					} else {
						locals.get(id).r = ex[0];
					}
				}
			case EField(e, f, isDouble):
				var ex:Array<Dynamic> = if(isAndParams(e2)) cast(e2, LuaAndParams).values; else [e2];
				var o:Dynamic = expr(e);
				if(o == null) {
					var sb:Null<String> = null;
					var type:Null<LuaVariableType> = null;
					LuaTools.recursion(e, function(e:LuaExpr) {
						switch(e.expr) {
							case EIdent(id):
								sb = id;
								type = if(locals.get(id) != null) LOCAL; else GLOBAL;
							case EField(_, f):
								sb = f;
								type = FIELD;
							case EArray(_, _):
								sb = 'integer index';
								type = FIELD;
							default:
								type = UNKNOWN;
						}
					});
					error(EInvalidAccess(sb, type));
				};
				set(o, f, ex[0], isDouble);
			case EArray(arr, index):
				var ex:Array<Dynamic> = if(isAndParams(e2)) cast(e2, LuaAndParams).values; else [e2];
				var array:Dynamic = expr(arr);
				var index:Dynamic = expr(index);
				if(array == null) {
					var sb:Null<String> = null;
					var type:Null<LuaVariableType> = null;
					LuaTools.recursion(arr, function(e:LuaExpr) {
						switch(e.expr) {
							case EIdent(id):
								sb = id;
								type = if(locals.get(id) != null) LOCAL; else GLOBAL;
							case EField(_, f):
								sb = f;
								type = FIELD;
							case EArray(_, _):
								sb = 'integer index';
								type = FIELD;
							default:
								type = UNKNOWN;
						}
					});
					error(EInvalidAccess(sb, type));
				}
				if(isTable(array)) return cast(array, LuaTable<Dynamic>).__write(array, index, ex[0]);
				array[index] = ex[0];
			default:
				error(EInvalidOp("="));
		}
	}

	function evalAssignOp(e1:LuaExpr, e2:LuaExpr, isLocal:Bool = false) {
		switch(e1.expr) {
			case EAnd(arr):
				for(i=>eval in arr) {
					var e2:Dynamic = expr(e2);
					var ex:Array<Dynamic> = if(isAndParams(e2)) cast(e2, LuaAndParams).values; else [e2];
					evalAssignOpExpr(eval, ex[i], isLocal);
				}
				if(isLocal) isLocal = false;
			case EIdent(id):
				var ex:Dynamic = expr(e2);
				var ex:Array<Dynamic> = if(isAndParams(ex)) cast(ex, LuaAndParams).values; else [ex];
				if(isLocal) {
					declared.push({n: id, old: locals.get(id)});
					locals.set(id, {r: ex[0]});
					isLocal = false;
				} else {
					if(locals.get(id) == null) {
						globals.set(id, ex[0]);
					} else {
						locals.get(id).r = ex[0];
					}
				}
			case EField(e, f, isDouble):
				var ex:Dynamic = expr(e2);
				var ex:Array<Dynamic> = if(isAndParams(ex)) cast(ex, LuaAndParams).values; else [ex];
				var o:Dynamic = expr(e);
				if(o == null) {
					var sb:Null<String> = null;
					var type:Null<LuaVariableType> = null;
					LuaTools.recursion(e, function(e:LuaExpr) {
						switch(e.expr) {
							case EIdent(id):
								sb = id;
								type = if(locals.get(id) != null) LOCAL; else GLOBAL;
							case EField(_, f):
								sb = f;
								type = FIELD;
							case EArray(_, _):
								sb = 'integer index';
								type = FIELD;
							default:
								type = UNKNOWN;
						}
					});
					error(EInvalidAccess(sb, type));
				};
				set(o, f, ex[0], isDouble);
			case EArray(arr, index):
				var ex:Dynamic = expr(e2);
				var ex:Array<Dynamic> = if(isAndParams(ex)) cast(ex, LuaAndParams).values; else [ex];
				var array:Dynamic = expr(arr);
				var index:Dynamic = expr(index);
				if(array == null) {
					var sb:Null<String> = null;
					var type:Null<LuaVariableType> = null;
					LuaTools.recursion(arr, function(e:LuaExpr) {
						switch(e.expr) {
							case EIdent(id):
								sb = id;
								type = if(locals.get(id) != null) LOCAL; else GLOBAL;
							case EField(_, f):
								sb = f;
								type = FIELD;
							case EArray(_, _):
								sb = 'integer index';
								type = FIELD;
							default:
								type = UNKNOWN;
						}
					});
					error(EInvalidAccess(sb, type));
				}
				if(isTable(array)) return cast(array, LuaTable<Dynamic>).__write(array, index, ex[0]);
				array[index] = ex[0];
			default:
				error(EInvalidOp("="));
		}
	}

	/**
	 * 点击输入文本
	 * @see https://github.com/HaxeFoundation/hscript/blob/master/hscript/Interp.hx#L568
	 */
	function makeIterator(v: Dynamic): Iterator<Dynamic> {
		#if js
		// don't use try/catch (very slow)
		if (v is Array)
			return (v : Array<Dynamic>).iterator();
		if (v.iterator != null)
			v = v.iterator();
		#else
		try
			v = v.iterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	/**
	 * 点击输入文本
	 * @see https://github.com/HaxeFoundation/hscript/blob/master/hscript/Interp.hx#L581
	 */
	function makeKeyValueIterator(v: Dynamic): KeyValueIterator<Dynamic, Dynamic> {
		#if js
		// don't use try/catch (very slow)
		if (v is Array)
			return (v : Array<Dynamic>).keyValueIterator();
		if (v.keyValueIterator != null)
			v = v.keyValueIterator();
		#else
		#if cpp
		// i need convert type to get map's keyValueIterator in cpp. (yeh
		if (isMap(v)) {
			v = cast(v, IMap<Dynamic, Dynamic>).keyValueIterator();
		} else
		#end
		try
			v = v.keyValueIterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	/**
	 * 点击输入文本
	 * @see https://github.com/HaxeFoundation/hscript/blob/master/hscript/Interp.hx#L606
	 */
	function forGenLoop(vk, vv, it, e) {
		var old = declared.length;
		var params:Array<Dynamic> = getParams(expr(it));
		final func = params[0];
		final isFunc = Reflect.isFunction(func);
		if(params.length == 1 && !isFunc) {
			declared.push({n: vk, old: locals.get(vk)});
			if(vk != null) {
				declared.push({n: vv, old: locals.get(vv)});
				var it = makeKeyValueIterator(func);
				while (it.hasNext()) {
					var v = it.next();
					locals.set(vk, {r: v.key});
					locals.set(vv, {r: v.value});
					if (!loopRun(() -> expr(e)))
						break;
				}
			} else {
				var it = makeIterator(func);
				while (it.hasNext()) {
					var v = it.next();
					locals.set(vk, {r: v.value});
					if (!loopRun(() -> expr(e)))
						break;
				}
			}
		} else {
			if(!isFunc) error(EInvalidIterator(null));
			final state = params[1];
			var current = params[2];
			declared.push({n: vk, old: locals.get(vk)});
			if(vk != null) {
				declared.push({n: vv, old: locals.get(vv)});
				var results:Array<Dynamic> = getParams(func(state, current));
				while (results[1] != null) {
					current = results[0];
					locals.set(vk, {r: results[0]});
					locals.set(vv, {r: results[1]});
					if (!loopRun(() -> expr(e)))
						break;
					results = getParams(func(state, current));
				}
			} else {
				var results:Array<Dynamic> = getParams(func(state, current));
				while (results[1] != null) {
					current = results[0];
					locals.set(vv, {r: results[1]});
					if (!loopRun(() -> expr(e)))
						break;
					results = getParams(func(state, current));
				}
			}
		}
		restore(old);
	}

	/**
	 * 点击输入文本
	 * @see https://github.com/HaxeFoundation/hscript/blob/master/hscript/Interp.hx#L621
	 */
	inline function loopRun(f: Void->Void) {
		var cont = true;
		try {
			f();
		} catch (err:LuaStop) {
			switch (err) {
				case SContinue, SLabel:
				case SBreak:
					cont = false;
				case SReturn:
					throw err;
			}
		}
		return cont;
	}

	function restore(old: Int) {
		while (declared.length > old) {
			var d = declared.pop();
			locals.set(d.n, d.old);
		}
	}

	function restoreLabels(old: Int) {
		while(mlLabelsRecord.length > old) {
			var m = mlLabelsRecord.pop();
			markedLabels.set(m.n, m.old);
		}
	}

	function duplicate<T>(h: #if haxe3 Map<String, T> #else Hash<T> #end) {
		#if haxe3
		var h2 = new Map();
		#else
		var h2 = new Hash();
		#end
		for (k in h.keys())
			h2.set(k, h.get(k));
		return h2;
	}

	static function luastd_error(message:String, ?l:Int) {
		throw message;
	}

	static function luastd_pairs(it:Dynamic):LuaAndParams {
		return LuaAndParams.fromArray([luastd_next, it, null]);
	}

	static function ipairs_fu(state:LuaTable<Dynamic>, control:Int) {
		state = LuaCheckType.checkTable(state);
		control = LuaCheckType.checkInteger(control);
		control++;
		final v = state.get(control);
		if(control < state.nextIndex && v != null) {
			return LuaAndParams.fromArray([control, v]);
		}
		return LuaAndParams.fromArray([null]);
	}

	static function luastd_next(state:LuaTable<Dynamic>, control:Dynamic) {
		state = LuaCheckType.checkTable(state);
		final nextKey = state._keys[(control == null ? -1 : state._keys.indexOf(control)) + 1];
		if(nextKey != null) {
			return LuaAndParams.fromArray([nextKey, state.get(nextKey)]);
		}
		return LuaAndParams.fromArray([null]);
	}

	inline function exists(id:String):Bool {
		return locals.get(id) != null || globals.exists(id);
	}

	inline function getParams(sb:Dynamic):Array<Dynamic> {
		if(sb is LuaAndParams) return cast(sb, LuaAndParams).values;
		return [sb];
	}

	inline function getParamsFirst(sb:Dynamic):Dynamic {
		if(sb is LuaAndParams) return cast(sb, LuaAndParams).values[0];
		return sb;
	}

	public function error(err:LuaErrorDef, ?line:Int):Dynamic {
		throw new LuaError(err, line ?? (curExpr == null ? 0 : curExpr.line));
		return null;
	}

	inline static function isMap(o: Dynamic): Bool {
		return (o is IMap);
	}

	inline static function isTable(o: Dynamic): Bool {
		return (o is LuaTable);
	}

	inline static function isAndParams(o: Dynamic): Bool {
		return (o is LuaAndParams);
	}

	inline static function isMetaTable(o: Dynamic): Bool {
		return (o is LuaTable) && cast(o, LuaTable<Dynamic>).metaTable != null;
	}
}

enum abstract LuaTyper(Int) from Int to Int {
	public var TNONE:LuaTyper;

	public var TNIL:LuaTyper;

	public var TBOOLEAN:LuaTyper;

	public var TNUMBER:LuaTyper;

	public var TSTRING:LuaTyper;

	public var TTABLE:LuaTyper;

	public var TFUNCTION:LuaTyper;

	@:to inline function __toString():String {
		return LuaCheckType.toTypeString(this);
	}
}

class LuaCheckType {
	public static inline function checkType(v:Dynamic):LuaTyper {
		return switch(Type.typeof(v)) {
			case Type.ValueType.TInt, Type.ValueType.TFloat: TNUMBER;
			case Type.ValueType.TClass(String): TSTRING;
			case Type.ValueType.TFunction: TFUNCTION;
			case Type.ValueType.TNull: TNIL;
			case Type.ValueType.TBool: TBOOLEAN;
			case Type.ValueType.TClass(LuaTable): TTABLE;
			case _: TNONE;
		}
	}

	public static function toTypeString(idx:Int):String {
		return switch(idx) {
			case TNIL: "nil";
			case TBOOLEAN: "bool";
			case TNUMBER: "number";
			case TSTRING: "string";
			case TTABLE: "table";
			case TFUNCTION: "function";
			case _: "none";
		}
	}

	public inline static function isInteger(v:Dynamic):Bool {
		if(checkType(v) == TNUMBER) return Std.int(v) == v;
		return false;
	}

	public inline static function isNotSpecialValue(v:Dynamic):Bool {
		return switch(checkType(v)) {
			case TNUMBER, TSTRING: true;
			default: false;
		}
	}

	public static function checkInteger(v:Dynamic):Null<Int> {
		if(isInteger(v)) return Std.int(v);
		throw "expected int, got " + checkType(v);
		return null;
	}

	public static function checkNumber(v:Dynamic):Null<Float> {
		if(checkType(v) == TNUMBER) return v;
		throw "expected number, got " + checkType(v);
		return null;
	}

	public static function checkString(v:Dynamic):Null<String> {
		if(checkType(v) == TSTRING) return v;
		throw "expected string, got " + checkType(v);
		return null;
	}

	public static function checkTable(v:Dynamic):Null<LuaTable<Dynamic>> {
		if(checkType(v) == TTABLE) return v;
		throw "expected table, got " + checkType(v);
		return null;
	}

	public static function checkNotSpecialValue(v:Dynamic):Null<Dynamic> {
		return switch(checkType(v)) {
			case TNUMBER, TSTRING: v;
			case _:
				throw "invalid value(" + checkType(v) + ")";
				null;
		}
	}
}

class Lua_tonumber {
	/**
	 * 尝试将任意值转换为 Float 数字
	 * @param e 要转换的值
	 * @param base 进制 (2-36)，默认为10
	 * @return Null<Float> 转换后的数字，如果无法转换则返回 null
	 */
	public static function tonumber(e:Dynamic, ?base:Int):Null<Float> {
		if (e == null) return null;
		var type = LuaCheckType.checkType(e);

		// 如果已经是数字，直接返回
		if (type == TNUMBER && base == null) {
			return Std.parseFloat(Std.string(e));
		} else if(type == TNUMBER) throw "invalid convert number to number in base";

		// 如果是布尔值，无法转换
		if (type == TBOOLEAN) {
			return null;
		}

		// 如果是字符串，尝试转换
		if (type == TSTRING) {
			var s:String = e;
			s = StringTools.trim(s);

			if (s == "") return null;

			// 处理指定进制
			if (base != null) {
				// 检查进制是否有效
				if (base < 2 || base > 36) return null;

				return parseWithBase(s, base);
			} else {
				return parseDecimal(s);
			}
		}

		// 其他类型无法转换
		return null;
	}
	
	/**
	 * 解析指定进制的字符串
	 */
	private static function parseWithBase(s:String, base:Int):Null<Float> {
		// 处理符号
		var sign:Float = 1;
		if (s.charAt(0) == '-') {
			sign = -1;
			s = s.substr(1);
		} else if (s.charAt(0) == '+') {
			s = s.substr(1);
		}

		if (s == "") return null;

		var digits = "0123456789abcdefghijklmnopqrstuvwxyz";
		var result:Float = 0;

		for (i in 0...s.length) {
			var char = s.charAt(i).toLowerCase();
			var value = digits.indexOf(char);

			// 检查字符是否在当前进制范围内
			if (value == -1 || value >= base) {
				return null;
			}

			result = result * base + value;
		}

		return sign * result;
	}

	static var decimalPattern = ~/^[-+]?(\d+\.?\d*|\.\d+)$/;
	static var scientificPattern = ~/^[-+]?(\d+\.?\d*|\.\d+)[eE][-+]?\d+$/;
	static var hexPattern = ~/^(0[xX])[0-9a-fA-F]+$/;

	/**
	 * 解析十进制字符串（支持小数和科学计数法）
	 */
	private static function parseDecimal(s:String):Null<Float> {

		// 尝试十六进制
		if (hexPattern.match(s)) {
			var hexStr = s.substr(2);
			return parseWithBase(hexStr, 16);
		}

		// 尝试普通十进制或科学计数法
		if (decimalPattern.match(s) || scientificPattern.match(s)) {
			return Std.parseFloat(s);
		}

		return null;
	}
}
