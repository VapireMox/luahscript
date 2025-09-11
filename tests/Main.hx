package;

// import luahscript.LuaParser;
// import luahscript.LuaInterp;
import lhscript.LHScript;
// import luahscript.exprs.LuaExpr;

class Main {
	public static function main() {
		var input:String = haxe.Resource.getString("test.lua");
		var interp = new LHScript(input);
		interp.setVar("Haxe", MyHaxeClass);

		//自选两个 不过可以更好的处理print
	    interp.setPrintHandler(function(line, msg) {
            trace('LUA PRINT[$line]: $msg');
        });
        
        interp.setErrorHandler(function(err) {
            trace('LUA ERROR: $err');
        });
		
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
