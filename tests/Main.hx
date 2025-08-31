package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var e = new LuaParser().parseFromString(sys.io.File.getContent("/storage/emulated/0/haxe/luahscript/test.lua"));
		trace(e);
		var interp = new LuaInterp();
		final f = interp.execute(e);
		trace(f());
		trace("globals: " + interp.globals);
	}
}