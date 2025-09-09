package luahscript;

import luahscript.*;
import luahscript.LuaInterp; 

class LHScript extends LuaInterp
{
	private var parsedCode:String;
    
    public function new(){
	   super();
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

			this.globals.set("package", { loaded: loadedModules });

			this.expr(moduleFuncExpr);
			var mainFunc:Dynamic = this.resolve("globalModules");
			if (mainFunc == null || LuaCheckType.checkType(mainFunc) != TFUNCTION) {
				this.globals.remove("package");
				throw "Module " + moduleName + " did not define a main function.";
			}

			var callResult = try Reflect.callMethod(null, mainFunc, []) catch(e:haxe.Exception) throw error(ECustom(Std.string(e)));
			var result = callResult; 

			this.globals.remove("globalModules");
			this.globals.remove("package");

			if (result == null) {
				throw "Module " + moduleName + " did not return a value.";
			}

			loadedModules.set(moduleName, result);
			return result;
		});
		#end
  }
  //lol
  
  public function executeCode(code:String, ?args:Array<Dynamic>):String {
    super.execute(new LuaParser().parseFromString(code), args); 
  }

  public function Lua_Helper_addCallback(func:String, args:Dynamic):Void
  {
    return globals.set(func, args);
  }
}
