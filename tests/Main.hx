package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var e = new LuaParser().parseFromString(haxe.Resource.getString("test.lua"));
		var interp = new LuaInterp();
		final f = interp.execute(e);
		trace(f());
	}
}
