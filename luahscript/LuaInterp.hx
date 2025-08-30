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

	var binops:Map<String, LuaExpr->LuaExpr->Dynamic>;

	var curExpr:LuaExpr;
	var return_value:Array<Dynamic>;

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
		binops.set("^", function(left, right) {
			return Math.pow(me.expr(left), me.expr(right));
		});
		binops.set("*", function(left, right) {
			return me.expr(left) * me.expr(right);
		});
		binops.set("/", function(left, right) {
			return me.expr(left) / me.expr(right);
		});
		binops.set("//", function(left, right) {
			final result = me.expr(left) / me.expr(right);
			return if(result >= 0) Math.floor(result);
			else Math.ceil(result);
		});
		binops.set("%", function(left, right) {
			return me.expr(left) % me.expr(right);
		});
		binops.set("+", function(left, right) {
			return me.expr(left) + me.expr(right);
		});
		binops.set("-", function(left, right) {
			return me.expr(left) - me.expr(right);
		});
		binops.set("..", function(left, right) {
			return me.expr(left) + me.expr(right);
		});
		binops.set("<", function(left, right) {
			return me.expr(left) < me.expr(right);
		});
		binops.set(">", function(left, right) {
			return me.expr(left) > me.expr(right);
		});
		binops.set("<=", function(left, right) {
			return me.expr(left) <= me.expr(right);
		});
		binops.set(">=", function(left, right) {
			return me.expr(left) >= me.expr(right);
		});
		binops.set("~=", function(left, right) {
			return me.expr(left) != me.expr(right);
		});
		binops.set("==", function(left, right) {
			return me.expr(left) == me.expr(right);
		});
		binops.set("and", function(left, right) {
			final a = me.expr(left);
			final b = me.expr(left);
			if(a == null || a == false) return a;
			return b;
		});
		binops.set("or", function(left, right) {
			final a = me.expr(left);
			final b = me.expr(left);
			if(a != null || a != false) return a;
			return b;
		});

		globals = new Map();
		globals.set("print", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var buf = new StringBuf();
			for(i=>arg in args) {
				buf.add(Std.string(arg));
				if(i < args.length - 1) buf.add("\t");
			}
			Sys.println(buf.toString());
		}));
		globals.set("pairs", function(it:Dynamic):KeyValueIterator<Dynamic, Dynamic> {
			if(it is LuaTable) {
				return new LuaTable.LuaTablePairsIterator(cast it);
			}
			throw "It only used in table.";
			return null;
		});
		globals.set("ipairs", function(it:Dynamic):KeyValueIterator<Dynamic, Dynamic> {
			if(it is LuaTable) {
				return new LuaTable.LuaTableIpairsIterator(cast it);
			}
			throw "It only used in table.";
			return null;
		});
		globals.set("setmetatable", function(o:LuaTable<Dynamic>, meta:LuaTable<Dynamic>):LuaTable<Dynamic> {
			o.metaTable = meta;
			return o;
		});
		globals.set("getmetatable", function(o:LuaTable<Dynamic>):LuaTable<Dynamic> {
			return o.metaTable;
		});
	}

	public function execute(expr:LuaExpr):Dynamic {
		isLocal = false;
		locals = new Map();
		declared = new Array();
		return this.expr(expr);
	}

	function exprReturn(e:LuaExpr):Array<Dynamic> {
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
		return [];
	}

	var isLocal:Bool;
	function expr(e:LuaExpr):Dynamic {
		this.curExpr = e;
		switch(e.expr) {
			case EConst(c):
				switch(c) {
					case CInt(sb): return sb;
					case CFloat(sb): return sb;
					case CString(sb, _): return sb;
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
				var e:Dynamic = expr(e);
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

				return get(e, f);
			case ELocal(e):
				isLocal = true;
				return expr(e);
			case EBinop(op, e1, e2):
				if(op == "=") {
					evalAssignOp(e1, e2);
					return null;
				}
				var fop = binops.get(op);
				if(fop != null) return fop(e1, e2);
				return error(EInvalidOp(op));
			case EPrefix(prefix, e):
				var v:Dynamic = expr(e);
				return switch(prefix) {
					case "#":
						if(v.length != null) prefix.length else 0;
					case "not":
						!luaBool(e);
					case _:
						error(EInvalidOp(prefix));
				}
			case ECall(e, params):
				var func = expr(e);
				final args:Array<Dynamic> = [for(p in params) expr(p)];
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
			case ETd(ae):
				var old = declared.length;
				for(e in ae) expr(e);
				restore(old);
			case EAnd(sb):
				return (sb == null ? [] : [for(e in sb) expr(e)]);
			case EIf(cond, body, eis, eel):
				final newCond = expr(cond);
				if(luaBool(newCond)) {
					expr(body);
				} else {
					var crosseis = false;
					if(eis != null) for(e in eis) {
						final newCond = expr(e.cond);
						if(luaBool(newCond)) {
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
				while(luaBool(expr(cond))) {
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
				var me = this;
				var isDouble = false;
				var obj:Dynamic = null;
				final names = (info != null ? info.names : []);
				if(info != null) {
					isDouble = info.isDouble;
					var preName:Null<String> = null;
					if(names.length > 1) for(i=>name in names) {
						if(i == 0) {
							obj = resolve(name);
						} else {
							if(obj == null) error(EInvalidAccess(preName, (preName == null ? UNKNOWN : (i > 1 ? FIELD : (locals.get(preName) != null ? LOCAL : GLOBAL)))));
							if(i < names.length - 1) obj = get(obj, name);
						}
						preName = name;
					}
					if(isDouble && isLocal) error(ECustom("Cannot define the field of a global variable as local"));
				}
				var f = Reflect.makeVarArgs(function(params:Array<Dynamic>) {
					var old = me.declared.length;
					for(i=>arg in args) {
						me.declared.push({ n : arg, old : locals.get(arg) });
						me.locals.set(arg, {r: params[i]});
					}
					var r = me.exprReturn(e);
					me.restore(old);
					return r;
				});
				if(names.length > 0) {
					final name = names[names.length - 1];
					if(obj != null) {
						obj.set(name, f);
					} else {
						if(isLocal) {
							declared.push({n: name, old: locals.get(name)});
							locals.set(name, {r: f});
							isLocal = false;
						} else {
							globals.set(name, f);
						}
					}
				}
				return f;
			case EIgnore:
			case EReturn(e):
				return_value = if(e != null) switch(e.expr) {
					case EAnd(ae): [for(e in ae) expr(e)];
					case _: [expr(e)];
				} else [];
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
				if(isTable(o)) return cast(o, LuaTable<Dynamic>).get(expr(index));
				return o[expr(index)];
			case ETable(fls):
				var table = new LuaTable<Dynamic>();
				var i = 0;
				for(fl in fls) {
					var value = expr(fl.v);
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

	function get(obj:Dynamic, f:String):Dynamic {
		if(isTable(obj)) return cast(obj, LuaTable<Dynamic>).get(f);
		return Reflect.getProperty(obj, f);
	}

	function set(obj:Dynamic, f:String, value:Dynamic) {
		if(isTable(obj)) return cast(obj, LuaTable<Dynamic>).set(f, value);
		Reflect.setProperty(obj, f, value);
	}

	function evalAssignOp(e1:LuaExpr, e2:LuaExpr, cancel:Bool = false) {
		switch(e1.expr) {
			case EAnd(arr):
				var ex:Array<Dynamic> = switch(e2.expr) {
					case EAnd(ea): ea;
					case _: [e2];
				}
				for(i=>e in arr) {
					evalAssignOp(e, ex[i], true);
				}
				if(isLocal) isLocal = false;
			case EIdent(id):
				var ex:Array<Dynamic> = exprAnd(e2);
				if(isLocal) {
					if(!cancel) isLocal = false;
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
				var ex:Array<Dynamic> = exprAnd(e2);
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
				set(o, f, ex[0]);
			case EArray(arr, index):
				var ex:Array<Dynamic> = exprAnd(e2);
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
				if(isTable(array)) return cast(array, LuaTable<Dynamic>).set(index, ex[0]);
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

	function exprAnd(e:LuaExpr):Array<Dynamic> {
		var values:Array<Dynamic> = [];
		switch(e.expr) {
			case EAnd(ae):
				for(e in ae) values.push(expr(e));
			case _:
				values.push(expr(e));
		}
		return values;
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

	inline static function luaBool(q:Dynamic):Bool {
		return q != false && q != null;
	}
}

