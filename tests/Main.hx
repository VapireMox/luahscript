package;

import luahscript.LuaInterp;
import luahscript.LuaParser;
import luahscript.exprs.*;
import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var input:String = haxe.Resource.getString("test.lua");

		var parser = new LuaParser();
		var interp = new LuaInterp();

		final func = interp.execute(parser.parseFromString(input));

		// input args
		func("apple", "banana");
	}
}


/*class MyHaxeClass {
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
*/