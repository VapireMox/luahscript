package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var input:String = haxe.Resource.getString("test.lua");
		var parser = new LuaParser();
		var interp = new LuaInterp();
		try {
			trace(interp.execute(parser.parseFromString(input))());
		} catch(e) {
			trace("Error: " + Std.string(e));
		}
	}
}
