package luahscript;

import luahscript.*;
import luahscript.LuaInterp; 

@:access(luahscript.LuaInterp)
class LHScript
{
	public var Interp:LuaInterp;
	private var loadedModules:Map<String, Dynamic>;
	
    public function new(){
	   Interp = new LuaInterp();
       #if sys 
        //纪念用的
		Lua_Helper_addCallback("require", function(moduleName:String):Dynamic {
			if (loadedModules.exists(moduleName)) {
				return loadedModules.get(moduleName);
			}

			var filePath = moduleName.split(".").join("/") + ".lua";
			if (!sys.FileSystem.exists(filePath)) {
				if (sys.FileSystem.exists("tests/" + filePath)) {
					filePath = "tests/" + filePath;
				} else {
					throw "module '" + moduleName + "' not found";
				}
			}

			var content = sys.io.File.getContent(filePath);
			var parser = new LuaParser().parseFromString(content);
			var moduleFuncExpr = parser;

			Interp.globals.set("package", { loaded: loadedModules });

			expr(moduleFuncExpr);
			var mainFunc:Dynamic = Interp.resolve("globalModules");
			if (mainFunc == null || LuaCheckType.checkType(mainFunc) != TFUNCTION) {
				Interp.globals.remove("package");
				throw "Module " + moduleName + " did not define a main function.";
			}

			var callResult = try Reflect.callMethod(null, mainFunc, []) catch(e:haxe.Exception) throw error(ECustom(Std.string(e)));
			var result = callResult; 

			Interp.globals.remove("globalModules");
			Interp.globals.remove("package");

			if (result == null) {
				throw "Module " + moduleName + " did not return a value.";
			}

			loadedModules.set(moduleName, result);
			return result;
		});
		#end
  }
  //lol

  public function call(fun:String, ?args:Array<Dynamic>):Dynamic
  {
	return Interp.call(fun, args);
  }
  
  public function executeCode(code:String, ?args:Array<Dynamic>):Dynamic {
    return Interp.execute(new LuaParser().parseFromString(code), args); 
  }

  public function Lua_Helper_addCallback(func:String, args:Dynamic):Void
  {
    return Interp.globals.set(func, args);
  }
}
