package lhscript;

import luahscript.LuaInterp;
import luahscript.LuaTable;
import luahscript.LuaTools;
import luahscript.LuaParser;
import luahscript.exprs.LuaExpr;
import luahscript.LuaAndParams;
import haxe.Constraints.IMap;

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
			this.scriptContent = scriptContent;
		}
		initCustomFunctionHandling();
	}
	

	public static function fromFile(path:String):LHScript {
		#if openfl
		var content = openfl.Assets.getText(path);
		#elseif sys
		var content = sys.io.File.getContent(path);
		#else
		var content = path;
		#end
		return new LHScript(content);
	}
	

	public static function fromString(content:String):LHScript {
		return new LHScript(content);
	}
	

	public function setVar(name:String, value:Dynamic):Void {
		interp.globals.set(name, value);
	}
	

	private function convertHaxeToLua(code:String):String {
		code = ~/0x([0-9a-fA-F]+)/g.replace(code, "tonumber('0x$1', 16)");
		code = ~/(\w+)\.(\w+)\s*\(([^)]*)\)/g.replace(code, "$1:$2($3)");
		return code;
	}
	

	public function setErrorHandler(callback:String->Void):Void {
		onError = callback;
	}

	public function setPrintHandler(callback:Int->String->Void):Void {
		onPrint = callback;
		interp.globals.set("print", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var buf = new StringBuf();
			for(i=>arg in args) {
				buf.add(Std.string(arg));
				if(i < args.length - 1) buf.add("\t");
			}
			if (onPrint != null) {
				onPrint((interp.curExpr != null ? interp.curExpr.line : 0) , buf.toString());
			}
		}));
	}
	

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
		return interp.globals.get(name);
	}

	public function execute():Void {
		if (scriptContent != null) {
			var expr = parser.parseFromString(scriptContent);
			interp.execute(expr)();
		}
	}
	

	public function callFunc(funcName:String, ?args:Array<Dynamic>):Dynamic {
		if (args == null) args = [];
		
		lastCalledFunction = funcName;
		lastCalledScript = this;
		
		try {
			if (interp == null) return "FUNC_CONT";
			
			var func = null;
			try {
				func = interp.globals.get(funcName);
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
			}
			return "FUNC_CONT";
		}
	}
	

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
				}
				results.push("FUNC_CONT");
			}
		}
		
		return results;
	}
	

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
		var func = interp.globals.get(funcName);
		return isFunction(func);
	}

	public function run(code:String):Dynamic {
		try {
			var expr = parser.parseFromString(code);
			return interp.execute(expr)();
		} catch (e:Dynamic) {
			if (onError != null) {
				onError("Lua error: " + Std.string(e));
			}
			return null;
		}
	}

	function initVar():Void {

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
	

	public function handleHaxeClassInstantiation(obj:Dynamic, methodName:String, args:Array<Dynamic>):Dynamic {

		if (methodName == "new") {
			var haxeClass:Class<Dynamic> = null;
			if (Std.isOfType(obj, Class)) {
				haxeClass = cast obj;
			} else {
				var className:String = null;
				if (Std.isOfType(obj, String)) {
					className = cast obj;
				} else {
					if (obj != null) {
						var objClass = Type.getClass(obj);
						if (objClass != null) {
							className = Type.getClassName(objClass);
						}
					}
				}

				if (className != null) {
					haxeClass = haxeClasses.get(className);
				if (haxeClass == null) {
					haxeClass = Type.resolveClass(className);
				}
				}
				
				if (haxeClass == null) {
					throw "Attempt to call 'new' on an object that is not a recognized class or type: " + Std.string(obj) + " (resolved class name: " + (className != null ? className : "null") + ")";
				}
			}
			
			try {
				var instance:Dynamic = null;
				#if neko
				if (Reflect.hasField(haxeClass, "__new__")) {
					instance = Reflect.callMethod(haxeClass, Reflect.field(haxeClass, "__new__"), args);
				} else {
				#end
				instance = Type.createInstance(haxeClass, args);
				#if neko
				}
				#end
				
				var instanceWrapper = new luahscript.LuaTable<Dynamic>();
				
				// 创建元表来存储元方法
				var metaTable = new luahscript.LuaTable<Dynamic>();
				metaTable.set("__index", function(table:Dynamic, propertyName:String):Dynamic {
					// 尝试获取实例对象的属性或方法
					if (Reflect.hasField(instance, propertyName)) {
						var value = Reflect.field(instance, propertyName);
						// 如果是方法，返回绑定到实例的函数
						if (Reflect.isFunction(value)) {
							return Reflect.makeVarArgs(function(varArgs:Array<Dynamic>) {
								var callArgs:Array<Dynamic> = [];
								if (varArgs != null) {
									for(a in varArgs) callArgs.push(a);
								}
								return Reflect.callMethod(instance, value, callArgs);
							});
						}
						return value;
					} else {
						try {
							var value = Reflect.getProperty(instance, propertyName);
							// 如果是方法，返回绑定到实例的函数
							if (Reflect.isFunction(value)) {
								return Reflect.makeVarArgs(function(varArgs:Array<Dynamic>) {
									var callArgs:Array<Dynamic> = [];
									if (varArgs != null) {
										for(a in varArgs) callArgs.push(a);
									}
									return Reflect.callMethod(instance, value, callArgs);
								});
							}
							return value;
						} catch (e:Dynamic) {
							return null;
						}
					}
				});

				metaTable.set("__newindex", function(table:Dynamic, propertyName:String, value:Dynamic):Void {
					Reflect.setProperty(instance, propertyName, value);
				});

				// 设置实例包装器的元表
				instanceWrapper.metaTable = metaTable;
				
				// 也存储实例引用在包装器中
				instanceWrapper.set("__instance", instance);
				
				return instanceWrapper;
			} catch (err:haxe.Exception) {
				throw "Failed to instantiate class " + Type.getClassName(haxeClass) + ": " + Std.string(err);
			}
		}
		
		return null;
	}
	

	public function handleMethodCall(obj:Dynamic, methodName:String, args:Array<Dynamic>, isDoubleColon:Bool):Dynamic {

		var instantiationResult = handleHaxeClassInstantiation(obj, methodName, args);
		if (instantiationResult != null) {
			return instantiationResult;
		}
		
		var isClassObject = false;
		if (Std.isOfType(obj, luahscript.LuaTable)) {
			var table = cast(obj, luahscript.LuaTable<Dynamic>);
			if (table.metaTable != null && table.metaTable.keyExists("__call")) {
				isClassObject = true;
			}
		}

		if (isDoubleColon && !isClassObject) {
			args.insert(0, obj);
		}
		

		var method:Dynamic = null;
		if (Reflect.isObject(obj) && !Std.isOfType(obj, luahscript.LuaTable)) {
			if (Reflect.hasField(obj, methodName)) {
				method = Reflect.field(obj, methodName);
			} else {

				try {
					method = Reflect.getProperty(obj, methodName);
				} catch (e:Dynamic) {

					method = null;
				}
			}
		}
		
		if (method != null && Reflect.isFunction(method)) {
			try {
				return Reflect.callMethod(obj, method, args);
			} catch (e:haxe.Exception) {
				throw "Error calling method '" + methodName + "': " + Std.string(e);
			}
		}
		

		if (Std.isOfType(obj, luahscript.LuaTable)) {
			method = cast(obj, luahscript.LuaTable<Dynamic>).get(methodName);
			if (method != null && Reflect.isFunction(method)) {
				return Reflect.callMethod(null, method, args);
			}
		}
		
		throw "Method '" + methodName + "' not found on object: " + Std.string(obj);
	}
	

	public function callFunction(funcExpr:Dynamic, ?args:Array<Dynamic>):Dynamic {
		if (args == null) args = [];
		
		if (Std.isOfType(funcExpr, String)) {
			return callFunc(cast funcExpr, args);
		} else if (Reflect.isObject(funcExpr)) {
			if (Reflect.hasField(funcExpr, "obj") && Reflect.hasField(funcExpr, "field")) {
				var obj = Reflect.field(funcExpr, "obj");
				var field = Reflect.field(funcExpr, "field");
				var isDoubleColon = Reflect.hasField(funcExpr, "isDouble") ? Reflect.field(funcExpr, "isDouble") : false;
				
				try {
					return handleMethodCall(obj, field, args, isDoubleColon);
				} catch (e:Dynamic) {
					if (onError != null) {
						onError("Error in enhanced function call: " + Std.string(e));
					}
					return null;
				}
			}
		}
		if (Reflect.isFunction(funcExpr)) {
			try {
				return Reflect.callMethod(null, funcExpr, args);
			} catch (e:Dynamic) {
				if (onError != null) {
					onError("Error calling function: " + Std.string(e));
				}
				return null;
			}
		}
		
		return null;
	}
	

	private function initCustomFunctionHandling():Void {
		var originalCallFunc = interp.globals.get("call");
		
		interp.globals.set("call", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			if (args.length >= 2) {
				var funcExpr = args[0];
				var callArgs = args.slice(1);
				
				var result = callFunction(funcExpr, callArgs);
				if (result != null) {
					return result;
				}
			}
			
			if (originalCallFunc != null && Reflect.isFunction(originalCallFunc)) {
				return Reflect.callMethod(null, originalCallFunc, args);
			}
			return null;
		}));
		
		var originalPcall = interp.globals.get("pcall");
		interp.globals.set("pcall", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			if (args.length >= 1) {
				var funcExpr = args[0];
				var callArgs = args.slice(1);
				
				try {
					var result = callFunction(funcExpr, callArgs);
					return luahscript.LuaAndParams.fromArray([true, result]);
				} catch (e:Dynamic) {
					return luahscript.LuaAndParams.fromArray([false, Std.string(e)]);
				}
			}
			if (originalPcall != null && Reflect.isFunction(originalPcall)) {
				return Reflect.callMethod(null, originalPcall, args);
			}
			return luahscript.LuaAndParams.fromArray([false, "bad argument #1 to pcall"]);
	}));
		
		interp.globals.set("__call", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			if (args.length >= 2) {
				var obj = args[0];
				var methodName = args[1];
				var callArgs = args.slice(2);
				
				if (Reflect.isObject(obj) && Reflect.hasField(obj, "__call")) {
					var __call = Reflect.field(obj, "__call");
					if (Reflect.isFunction(__call)) {
						return Reflect.callMethod(obj, __call, [methodName, callArgs]);
					}
				}
			}
			return null;
		}));
	}
	

	public function createMethodCall(obj:Dynamic, methodName:String, isDoubleColon:Bool = false):Dynamic {
		return {
			obj: obj,
			field: methodName,
			isDouble: isDoubleColon
		};
	}
	

	public function setupGlobalClass(luaName:String, haxeClass:Class<Dynamic>):Void {
		// Register the class in the haxeClasses map
		LHScript.registerHaxeClass(luaName, haxeClass);
		LHScript.registerHaxeClass(Type.getClassName(haxeClass), haxeClass);
		
		var classWrapper = new luahscript.LuaTable<Dynamic>();
		
		classWrapper.set("new", function() {
			var result = handleHaxeClassInstantiation(haxeClass, "new", []);
			return result;
		});
		
		classWrapper.set("__call", function(obj:Dynamic, methodName:String, ...args:Array<Dynamic>) {
			if (methodName == "new") {
				var finalArgs:Array<Dynamic> = args;
				if (args.length > 0 && args[0] == obj) {
					finalArgs = [];
					for (i in 1...args.length) {
						finalArgs.push(args[i]);
					}
				}
				return handleHaxeClassInstantiation(haxeClass, "new", finalArgs);
			}
			return null;
		});
		
		classWrapper.set("__index", function(methodName:String):Dynamic {
			if (methodName == "new") {
				return function(...args) {
					var finalArgs:Array<Dynamic> = args;
					if (args.length > 0 && args[0] == classWrapper) {
						finalArgs = [];
						for (i in 1...args.length) {
							finalArgs.push(args[i]);
						}
					}
					return handleHaxeClassInstantiation(haxeClass, "new", finalArgs);
				};
			}
			return classWrapper.get(methodName);
		});
		
		classWrapper.set("__len", function() {
			return 0;
		});
		
		interp.globals.set(luaName, classWrapper);
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
	
	public function isHaxeSyntaxEnabled():Bool {
		return enableHaxeSyntax;
	}
}
