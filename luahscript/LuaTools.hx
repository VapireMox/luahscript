package luahscript;

import luahscript.exprs.LuaExpr;

class LuaTools {
	public static function iter(e:LuaExpr, f:LuaExpr->Void) {
		switch(e.expr) {
			case EConst(_), EIdent(_):
			case EBreak, EContinue, EIgnore:
			case EParent(e):
				f(e);
			case EField(e, _):
				f(e);
			case ELocal(e):
				f(e);
			case EBinop(_, e1, e2):
				f(e1);
				f(e2);
			case EPrefix(_, e):
				f(e);
			case ECall(e, params):
				f(e);
				for(p in params) f(p);
			case ETd(ae):
				for(e in ae) f(e);
			case EAnd(ae):
				for(e in ae) f(e);
			case EIf(cond, body, eis, eel):
				f(cond);
				f(body);
				if(eis != null) for(e in eis) {
					f(e.cond);
					f(e.body);
				}
				if(eel != null) f(eel);
			case ERepeat(body, cond):
				f(body);
				f(cond);
			case EWhile(cond, e):
				f(cond);
				f(e);
			case EForNum(_, body, start, end, step):
				f(body);
				f(start);
				f(end);
				if(step != null) f(step);
			case EForGen(body, iterator, _):
				f(iterator);
				f(body);
			case EFunction(_, e):
				f(e);
			case EReturn(e):
				if(e != null) f(e);
			case EArray(e, index):
				f(e);
				f(index);
			case ETable(fl):
				for(fi in fl) {
					if(fi.key != null) f(fi.key);
					f(fi.v);
				}
		}
	}

	public static function recursion(e:LuaExpr, f:LuaExpr->Void) {
		switch(e.expr) {
			case EParent(e):
				recursion(e, f);
			case _:
				f(e);
		}
	}

	public static function map(e:LuaExpr, ef:LuaExpr->LuaExpr):LuaExpr {
		return {
			line: e.line,
			expr: switch(e.expr) {
				case EConst(_), EIdent(_): e.expr;
				case EBreak, EContinue, EIgnore: e.expr;
				case EParent(e): EParent(ef(e));
				case EField(e, f): EField(ef(e), f);
				case ELocal(e): ELocal(ef(e));
				case EBinop(op, e1, e2): EBinop(op, ef(e1), ef(e2));
				case EPrefix(prefix, e): EPrefix(prefix, ef(e));
				case ECall(e, params): ECall(e, [for(p in params) ef(p)]);
				case ETd(ae): ETd([for(e in ae) ef(e)]);
				case EAnd(ae): EAnd([for(e in ae) ef(e)]);
				case EIf(cond, body, eis, eel): EIf(ef(cond), ef(body), (eis == null ? eis : [for(e in eis) {cond: ef(e.cond), body: ef(e.body)}]), (eel == null ? eel : ef(eel)));
				case ERepeat(body, cond): ERepeat(ef(body), ef(cond));
				case EWhile(cond, e): EWhile(ef(cond), ef(e));
				case EForNum(v, body, start, end, step): EForNum(v, ef(body), ef(start), ef(end), (step == null ? step : ef(step)));
				case EForGen(body, iterator, v, k): EForGen(ef(body), ef(iterator), v, k);
				case EFunction(sb, e, ids): EFunction(sb, ef(e), ids);
				case EReturn(e): EReturn((e == null ? e : ef(e)));
				case EArray(e, index): EArray(ef(e), ef(index));
				case ETable(fl): ETable([for(f in fl) {v: ef(f.v), key: (f.key == null ? f.key : ef(f.key)), haveBK: f.haveBK}]);
			}
		};
	}

	public inline static function luaBool(q:Dynamic):Bool {
		return q != false && q != null;
	}
}