package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
<<<<<<< HEAD
		var e = new LuaParser().parseFromString(sys.io.File.getContent("../test.lua"));
		trace(e);
=======
		var e = new LuaParser().parseFromString(haxe.Resource.getString("test.lua"));
>>>>>>> 9480c8f (兼容其他平台编译，重写table)
		var interp = new LuaInterp();
		final f = interp.execute(e);
		trace(f());
	}
}
