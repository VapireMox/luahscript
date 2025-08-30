package luahscript;

import luahscript.LuaParser.LuaExpr;
import luahscript.LuaParser.LuaExprDef;

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
			case EObject(fl):
				for(fi in fl) {
					if(fi.key != null) f(fi.key);
					f(fi.v);
				}
		}
	}
}