package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var e = haxe.Resource.getString("test.lua");
		var interp = new LuaInterp();
		trace(interp.execute(new LuaParser().parseFromString(e)));
	}
}
