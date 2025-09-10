package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var input:String = haxe.Resource.getString("test.lua");
		var parser = new LuaParser();
		var interp = new LHScript(input);
		interp.execute();
		trace("LUA_PRINT " + onPrint);
		trace("LUA_ERROR " + onError);
	}
}
