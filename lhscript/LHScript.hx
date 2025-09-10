package lhscript;

import luahscript.LuaInterp;
import luahscript.LuaTable;
import luahscript.LuaTools;
import luahscript.LuaParser;
import luahscript.exprs.LuaExpr;

/**
 * Lua script parser
 */
@:access(luahscript.LuaInterp)
class LHScript {
    public var interp:LuaInterp;
    private var parser:LuaParser;
    private var scriptContent:String;
    private var loadedModules:Map<String, Dynamic>;
  
    private static var modules:Map<String, LHScript> = new Map<String, LHScript>();
   
    private static var haxeClasses:Map<String, Class<Dynamic>> = new Map<String, Class<Dynamic>>();
    
    public var parent(get, set):Dynamic;
    
    public var lastCalledFunction:String = '';
    public var lastCalledScript:LHScript = null;
    
    private var callCodeCache:Map<String, String> = new Map<String, String>();

    public var onError:String->Void = null;
    public var onPrint:Int->String->Void = null;

    public var enableGlobalErrorHandling:Bool = true;

    public var enableHaxeSyntax:Bool = true;
    private var originalScriptContent:String;

    private var scriptObject:Dynamic = {};
    
    public function new(?scriptContent:String) {
        interp = new LuaInterp();
        parser = new LuaParser();
        loadedModules = new Map();
        
        scriptObject = {};
        scriptObject.parent = null;

        setVar("script", scriptObject);
        initVar();
        
        this.enableHaxeSyntax = true;
        this.originalScriptContent = null;
        
        if (scriptContent != null) {
            this.originalScriptContent = scriptContent;
            this.scriptContent = processScriptContent(scriptContent);
        }
    }
    
    /**
     * Load Lua script from file path
     */
    public static function fromFile(path:String):LHScript {
        #if openfl
        var content = openfl.Assets.getText(path);
        #else
        var content = sys.io.File.getContent(path);
        #end
        return new LHScript(content);
    }
    
    /**
     * Create Lua script from string
     */
    public static function fromString(content:String):LHScript {
        return new LHScript(content);
    }
    
    /**
     * Set variable in Lua environment
     * Supports Haxe syntax conversion for string values
     */
    public function setVar(name:String, value:Dynamic):Void {
        interp.globals.set(name, value);
    }
    
    /**
     * Check if a string contains Haxe syntax that needs conversion
     */
    private function containsHaxeSyntax(code:String):Bool {
        // Check for hex numbers (0xFF0000)
        if (~/0x[0-9a-fA-F]+/.match(code)) {
            return true;
        }
        
        // Check for chained method calls (object.property.method())
        if (~/\w+\.\w+\.\w+\s*\(/.match(code)) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Convert Haxe syntax to Lua syntax
     */
    private function convertHaxeToLua(code:String):String {
        // Convert hex numbers
        code = ~/0x([0-9a-fA-F]+)/g.replace(code, "tonumber('0x$1', 16)");
        
        // Convert method calls
        // object.method() -> object:method()
        code = ~/(\w+)\.(\w+)\s*\(([^)]*)\)/g.replace(code, "$1:$2($3)");
        
        return code;
    }
    

    public function setErrorHandler(callback:String->Void):Void
        onError = callback;

    
    public function setPrintHandler(callback:Int->String->Void):Void {
        onPrint = callback;
        // Override print function in Lua
        interp.globals.set("print", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var buf = new StringBuf();
			for(i=>arg in args) {
				buf.add(Std.string(arg));
				if(i < args.length - 1) buf.add("\t");
			}
            if (onPrint != null) 
                onPrint(0, buf.toString());
		}));
    }
    
    /**
     * Set parent object
     * @param parent The parent object to set
     */
    public function setParent(parent:Dynamic):Void {
        this.parent = parent;
    }
    
    public function setupCallbacks(?location:String = "script", ?scriptName:String = "script"):Void {
        onError = function(err:String) {
            trace('Failed to execute script at ${location}: ${err}');
        };
        
        onPrint = function(line:Int, s:String) {
            trace('${scriptName}:${line}: ${s}');
        };
        
        setPrintHandler(onPrint);
    }
    
    public function getVar(name:String):Dynamic {
        return interp.resolve(name);
    }

    public function execute():Void {
        if (scriptContent != null) {
            try {
                var expr = parser.parseFromString(scriptContent);
                interp.execute(expr)();
            } catch (e:Dynamic) {
                if (enableGlobalErrorHandling) {
                    if (onError != null) {
                        onError(Std.string(e));
                    } else {
                        trace("Lua error: " + e);
                    }
                } else {
                    throw e;
                }
            }
        } else {
            trace("LHScript: No script content to execute");
        }
    }
    
    /**
     * Call Lua function
     */
    public function callFunc(funcName:String, ?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        
        lastCalledFunction = funcName;
        lastCalledScript = this;
        
        try {
            if (interp == null) return "FUNC_CONT";
            
            var func = null;
            try {
                func = interp.resolve(funcName);
            } catch (e:Dynamic) {
                return "FUNC_CONT";
            }
            if (func == null) {
                return "FUNC_CONT";
            }
            
            var result = Reflect.callMethod(null, func, args);
            return result;
        } catch (e:Dynamic) {
            if (onError != null) {
                onError("Lua error (" + funcName + "): " + Std.string(e));
            } else {
                trace("Lua error (" + funcName + "): " + e);
            }
            return "FUNC_CONT";
        }
    }
    
    //不常用
    public function callMultipleFunctions(funcNames:Array<String>, ?argsArray:Array<Array<Dynamic>> = null):Array<Dynamic> {
        var results:Array<Dynamic> = [];
        
        if (argsArray == null) argsArray = [];
        
        for (i in 0...funcNames.length) {
            var funcName = funcNames[i];
            var args:Array<Dynamic> = (i < argsArray.length) ? argsArray[i] : [];
            
            try {
                var result = callFunc(funcName, args);
                results.push(result);
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Lua error (calling multiple functions - " + funcName + "): " + Std.string(e));
                } else {
                    trace("Lua error (calling multiple functions - " + funcName + "): " + e);
                }
                results.push("FUNC_CONT");
            }
        }
        
        return results;
    }
    
    //不常用
    public function callFuncG(prefix:String, ?args:Array<Dynamic> = null):Array<Dynamic> {
        var results:Array<Dynamic> = [];
        var matchedFunctions:Array<String> = [];
        
        var allVars = getGlobalScope();
        if (allVars == null) return results;
        
        for (varName in allVars.keys()) {
            if (StringTools.startsWith(varName, prefix)) {
                var func = allVars.get(varName);
                if (func != null && isFunction(func)) {
                    matchedFunctions.push(varName);
                }
            }
        }
        
        for (funcName in matchedFunctions) {
            try {
                var result = callFunc(funcName, args);
                results.push(result);
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Lua error (calling functions by prefix - " + funcName + "): " + Std.string(e));
                } else {
                    trace("Lua error (calling functions by prefix - " + funcName + "): " + e);
                }
                results.push("FUNC_CONT");
            }
        }
        
        return results;
    }
    
    public function batchCallFun(functionCalls:Array<{funcName:String, ?args:Array<Dynamic>}>):Array<Dynamic> {
        var results:Array<Dynamic> = [];
        
        for (call in functionCalls) {
            try {
                var result = callFunc(call.funcName, call.args);
                results.push(result);
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Lua error (batch function call - " + call.funcName + "): " + Std.string(e));
                } else {
                    trace("Lua error (batch function call - " + call.funcName + "): " + e);
                }
                results.push("FUNC_CONT");
            }
        }
        
        return results;
    }

    private function isFunction(func:Dynamic):Bool {
        if (func == null) return false;
        return Reflect.isFunction(func);
    }
    
    public function hasFunc(funcName:String):Bool {
        var func = interp.resolve(funcName);
        return func != null;
    }

    public function run(code:String):Dynamic {
        try {
            var expr = parser.parseFromString(code);
            return interp.execute(expr)();
        } catch (e:Dynamic) {
            if (onError != null) {
                onError("Lua error: " + Std.string(e));
            } else {
                trace("Lua error: " + e);
            }
            return null;
        }
    }

    function initVar():Void {
        #if sys
		setVar("require", function(moduleName:String):Dynamic {
			if (loadedModules.exists(moduleName)) {
				return loadedModules.get(moduleName);
			}

			var filePath = moduleName.split(".").join("/") + ".lua";
            var file = '';
            if (sys.FileSystem.exists(filePath)) {
                file = filePath;
            } else {
                throw "module '" + moduleName + "' not found";
            }
			

			var content = sys.io.File.getContent(file);
			var parser = new LuaParser().parseFromString(content);
			var moduleFuncExpr = parser;

			setVar("package", { loaded: loadedModules });

			interp.expr(moduleFuncExpr);
			var mainsFunc:Dynamic = interp.resolve('main');
			if (mainsFunc == null || LuaCheckType.checkType(mainsFunc) != TFUNCTION) {
				interp.globals.remove("package");
				throw "Module " + moduleName + " did not define a main function.";
			}

			var callResult = try Reflect.callMethod(null, mainsFunc, []) catch(e:haxe.Exception) throw interp.error(ECustom(Std.string(e)));
			var result = callResult; 

			interp.globals.remove("main");
			interp.globals.remove("package");

			if (result == null) {
				throw "Module " + moduleName + " did not return a value.";
			}

			loadedModules.set(moduleName, result);
			return result;
		});
		#end
    }
    
    public function clear():Void {
        interp = new LuaInterp();
    }

    public function getVarNames():Array<String> {
        var names:Array<String> = [];
        var globals = getGlobalScope();
        if (globals != null) {
            for (name in globals.keys()) {
                names.push(name);
            }
        }
        return names;
    }

    public function getinterp():LuaInterp 
        return interp;

    public function setinterp(interps:LuaInterp):Void {
        interps = interp;
    }
    
    public static function registerModule(name:String, script:LHScript):Void {
        modules.set(name, script);
    }
    public static function getModule(name:String):LHScript {
        return modules.get(name);
    }
    
    public static function registerHaxeClass(luaName:String, haxeClass:Class<Dynamic>):Void {
        haxeClasses.set(luaName, haxeClass);
    }
    
    public static function getHaxeClass(luaName:String):Class<Dynamic> {
        return haxeClasses.get(luaName);
    }
    
    public static function registerHaxeClasses(classMap:Map<String, Class<Dynamic>>):Void {
        for (luaName in classMap.keys()) {
            haxeClasses.set(luaName, classMap.get(luaName));
        }
    }
    
    public function getGlobalScope():Map<String, Dynamic> {
        return interp.globals;
    }
    
    inline function get_script():Dynamic {
        return scriptObject;
    }
    
    inline function get_parent():Dynamic {
        return scriptObject.parent;
    }

    inline function set_parent(newParent:Dynamic):Dynamic {
        return scriptObject.parent = newParent;
    }
    
    private function processScriptContent(content:String):String {
        if (content == null) return null;
        
        if (enableHaxeSyntax) {
            return convertHaxeToLua(content);
        } else {
            return content;
        }
    }
    
    public function setScriptContent(content:String):Void {
        this.originalScriptContent = content;
        this.scriptContent = processScriptContent(content);
    }
    
    public function getOriginalScriptContent():String {
        return originalScriptContent;
    }
    
    public function setHaxeSyntaxEnabled(enable:Bool):Void {
        this.enableHaxeSyntax = enable;
        if (originalScriptContent != null) {
            this.scriptContent = processScriptContent(originalScriptContent);
        }
    }
    
    public function isHaxeSyntaxEnabled():Bool {
        return enableHaxeSyntax;
    }
}
