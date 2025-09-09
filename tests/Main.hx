package;

import luahscript.LuaParser;
import luahscript.LHScript;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var e = new LuaParser().parseFromString(haxe.Resource.getString("test.lua"));
		var interp = new LHScript();
		final f = interp.execute(e);
		trace(f());
	}
}
