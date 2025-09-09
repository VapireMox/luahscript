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
	
	var binops:Map<String, Dynamic->Dynamic->Dynamic>;

	var curExpr:LuaExpr;
	var return_value:LuaAndParams;
	var triple_value:LuaAndParams;

	public function new() {
		var me = this;
		binops = new Map();
		loadedModules = new Map();
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
		globals.set("error", lua_error);
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
						var newArgs:Array<Dynamic> = [];
						while(args.length > i - 1) {
							newArgs.push(args.shift());
						}
						return LuaAndParams.fromArray(newArgs);
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
		globals.set("pairs", function(it:Dynamic):KeyValueIterator<Dynamic, Dynamic> {
			return new LuaTable.LuaTablePairsIterator(LuaCheckType.checkTable(it));
		});
		globals.set("ipairs", function(it:Dynamic):KeyValueIterator<Dynamic, Dynamic> {
			return new LuaTable.LuaTableIpairsIterator(LuaCheckType.checkTable(it));
		});
		globals.set("setmetatable", function(o:LuaTable<Dynamic>, meta:LuaTable<Dynamic>):LuaTable<Dynamic> {
			LuaCheckType.checkTable(o).metaTable = LuaCheckType.checkTable(meta);
			return o;
		});
		globals.set("getmetatable", function(o:LuaTable<Dynamic>):LuaTable<Dynamic> {
			return LuaCheckType.checkTable(o).metaTable;
		});

		initLuaLibs(globals);
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

	public function execute(expr:LuaExpr, ?args:Array<Dynamic>):Dynamic {
		triple_value = LuaAndParams.fromArray(args ?? []);
		locals = new Map();
		declared = new Array();
		return this.expr(expr);
	}

	function exprReturn(e:LuaExpr):LuaAndParams {
		try {
			expr(e);
		} catch(s:LuaStop) {
			switch (s) {
				case LuaStop.SBreak:
					throw "break outside loop";
				case LuaStop.SContinue:
					throw "continue outside loop";
				case LuaStop.SReturn:
					if(return_value != null) return return_value;
			}
		}
		return new LuaAndParams();
	}

	public function expr(e:LuaExpr, isLocal:Bool = false):Dynamic {
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
				var obj:Dynamic = expr(e);
				if(e == null) {
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
				final left:Dynamic = expr(e1);
				final right:Dynamic = expr(e2);
				var fop = binops.get(op);
				if(fop != null) return fop(left, right);
				return error(EInvalidOp(op));
			case EPrefix(prefix, e):
				var v:Dynamic = expr(e);
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
						} else args.push(null);
						continue;
					}
					args.push(v);
				}
				switch(e.expr) {
					case EField(ef, f, double):
						var obj:Dynamic = expr(ef);
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

						final func:Dynamic = get(obj, f, double);
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
						if(double == true) args.insert(0, obj);
						return try Reflect.callMethod(null, func, args) catch(e:haxe.Exception) throw error(ECustom(Std.string(e)));
					case _:
						var func:Dynamic = expr(e);
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
						return try Reflect.callMethod(null, func, args) catch(e:haxe.Exception) throw error(ECustom(Std.string(e)));
				}
			case ETd(ae):
				var old = declared.length;
				for(e in ae) expr(e);
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
			case EIgnore:
			case EReturn(e):
				var v:Dynamic = (e == null ? null : expr(e));
				if(!isAndParams(v)) {
					return_value = LuaAndParams.fromArray([v]);
				} else {
					return_value = v;
				}
				throw LuaStop.SReturn;
			case EArray(e, index):
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
				}
				if(isTable(o) && o.metaTable.keyExists("__read")) return cast(o, LuaTable<Dynamic>).__read(o, expr(index));
				return o[expr(index)];
			case ETable(fls):
				var table = new LuaTable<Dynamic>();
				var i = 0;
				for(fl in fls) {
					var value = expr(fl.v);
					if(isAndParams(value)) {
						for(i=>v in cast(value, LuaAndParams).values) {
							table.set(i + 1, v);
						}
						break;
					}
					if(fl.key != null) {
						var key:Dynamic = switch(fl.key.expr) {
							case EIdent(id) if(fl.haveBK != true): 
								curExpr = fl.key;
								id;
							case _:
								expr(fl.key);
						}
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

	function call(fun:String, ?args:Array<Dynamic>):Dynamic {
		if (args == null)
			args = [];
		
		var ny:Dynamic = locals.get("func_" + fun); // function signature
		var isFunction:Bool = false;
		try {
			isFunction = ny != null && Reflect.isFunction(ny);
			if (!isFunction)
				throw 'Tried to call a non-function, for "$fun"';

			var ret = Reflect.callMethod(null, ny, args);
			locals.set(fun, ret);
			return ret;
		}
		catch (e:haxe.Exception) {
			
		}
		// @formatter:on
		return null;
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

	function checkKeyValueIterator(v: Dynamic): KeyValueIterator<Dynamic, Dynamic> {
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return cast v;
	}

	function checkIterator(v:Dynamic):Iterator<Dynamic> {
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return cast v;
	}

	/**
	 * 点击输入文本
	 * @see https://github.com/HaxeFoundation/hscript/blob/master/hscript/Interp.hx#L606
	 */
	function forGenLoop(vk, vv, it, e) {
		var old = declared.length;
		declared.push({n: vk, old: locals.get(vk)});
		if(vk != null) {
			declared.push({n: vv, old: locals.get(vv)});
			var it = checkKeyValueIterator(expr(it));
			while (it.hasNext()) {
				var v = it.next();
				locals.set(vk, {r: v.key});
				locals.set(vv, {r: v.value});
				if (!loopRun(() -> expr(e)))
					break;
			}
		} else {
			var it = checkIterator(expr(it));
			while (it.hasNext()) {
				var v = it.next();
				locals.set(vk, {r: v.value});
				if (!loopRun(() -> expr(e)))
					break;
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
				case SContinue:
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

	function lua_error(message:String, ?l:Int) {
			throw message;
		}

	inline function exists(id:String):Bool {
		return locals.get(id) != null || globals.exists(id);
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
			case _: "invalid";
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

