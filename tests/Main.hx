package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import lhscript.LHScript;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var input:String = haxe.Resource.getString("test.lua");
		var parser = new LuaParser();
		var interp = new LHScript(input);
		interp.execute();
		trace("LUA_PRINT " + interp.onPrint);
		trace("LUA_ERROR " + interp.onError);
	}
}
