package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var e = haxe.Resource.getString("test.lua");
		var interp = new LuaInterp();
		try {
			trace(interp.execute(e)());
		} catch(e) {
			trace("Error: " + Std.string(e));
		}
	}
}
