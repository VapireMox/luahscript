package luahscript.lualibs;

import luahscript.LuaInterp;
import luahscript.LuaTable;

@:build(luahscript.macros.LuaLibMacro.build())
@:noCompletion
class LuaCoroutineLib {
  private static var nextCoroutineId = 0;
  
  public static function lualib_create(func:Dynamic):LuaTable<Dynamic> {
    var coTable = new LuaTable<Dynamic>();
    coTable.set("_func", func);
    coTable.set("_status", "suspended");
    coTable.set("_id", nextCoroutineId++);
    return coTable;
  }

  @:multiArgs
  public static function lualib_resume(args:Array<Dynamic>):LuaTable<Dynamic> {
    if (args.length == 0) {
      var errorArray:Array<Dynamic> = [false, "missing coroutine argument"];
      return LuaTable.fromArray(errorArray);
    }
    
    var coTable:LuaTable<Dynamic> = args[0];
    var resumeArgs:Array<Dynamic> = args.slice(1);
    
    var status:String = coTable.get("_status");
    
    if (status == "dead") {
      var errorArray:Array<Dynamic> = [false, "cannot resume dead coroutine"];
      return LuaTable.fromArray(errorArray);
    }
    
    if (status == "running") {
      var errorArray:Array<Dynamic> = [false, "cannot resume running coroutine"];
      return LuaTable.fromArray(errorArray);
    }
    
    var func:Dynamic = coTable.get("_func");
    
    try {
      coTable.set("_status", "running");
      
      if (status == "suspended") {
        var result = Reflect.callMethod(null, func, resumeArgs);
        coTable.set("_status", "dead");
        var successArray:Array<Dynamic> = [true, result];
        return LuaTable.fromArray(successArray);
      }
      
      var successArray:Array<Dynamic> = [true];
      return LuaTable.fromArray(successArray);
      
    } catch (e:Dynamic) {
      coTable.set("_status", "dead");
      var errorArray:Array<Dynamic> = [false, "coroutine error: " + Std.string(e)];
      return LuaTable.fromArray(errorArray);
    }
  }

  @:multiArgs
  public static function lualib_yield(args:Array<Dynamic>):Void {
    // Simple yield implementation - just return without doing anything
    // In a real implementation, this would need to capture the current coroutine state
  }

  public static function lualib_status(coTable:LuaTable<Dynamic>):String {
    return coTable.get("_status");
  }

  public static function lualib_running():LuaTable<Dynamic> {
    var coTable = new LuaTable<Dynamic>();
    coTable.set("_status", "running");
    return coTable;
  }

  public static function lualib_wrap(func:Dynamic):LuaTable<Dynamic> {
    var wrapper = Reflect.makeVarArgs(function(args:Array<Dynamic>):Dynamic {
      var coTable = lualib_create(func);
      var result = lualib_resume([coTable].concat(args));
      return result.get(2);
    });
    
    var wrapperTable = new LuaTable<Dynamic>();
    wrapperTable.set("_func", wrapper);
    return wrapperTable;
  }
}
