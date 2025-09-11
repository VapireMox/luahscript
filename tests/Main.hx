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
		interp.setVar("Haxe", MyHaxeClass);
		interp.execute();
		trace("add(1, 1) " + interp.callFunc("add", [1, 1]));
		//trace("LUA_ERROR " + interp.onError);
	}
}
class MyHaxeClass {
    public var greeting:String;

    public function new(greeting:String = "Hello from Haxe!") {
        this.greeting = greeting;
    }

    public function sayHello():String {
        return greeting;
    }

    public function add(a:Int, b:Int):Int {
        return a + b;
    }
}
