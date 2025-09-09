package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var input:String = haxe.Resource.getString("test.lua");
		var parser = new LuaParser();
		var interp = new LuaInterp();
		trace(interp.execute(parser.parseFromString(input))());
	}
}
