package;

import luahscript.LuaParser;
import luahscript.LHScript;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var e = haxe.Resource.getString("test.lua");
		var interp = new LHScript();
		final f = interp.executeCode(e);
		trace(f());
	}
}
