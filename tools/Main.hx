package;

import luahscript.LuaInterp;
import luahscript.LuaParser;
import luahscript.LuaPrinter;
import luahscript.LuaAndParams;
import luahscript.LuaTable;
import luahscript.exprs.LuaError;
import luahscript.exprs.LuaExpr;
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

class Main {
	public static var keywords = ["run", "parse", "help", "print", "--help", "-help"];
	public static var haxelib:Dynamic = null;

	public static function main() {
		haxelib = haxe.Json.parse(haxe.Resource.getString("haxelib"));

		final args:Array<String> = Sys.args();
		final rootPath:String = args.pop();
		Sys.setCwd(rootPath);

		if(args.length == 0 ) {
			help();
		} else {
			if(keywords.contains(args[0])) {
				switch(args.shift()) {
					case "run":
						run(args);
					case "parse":
						parse(args);
					case "print":
						print(args);
					case "help", "--help", "-help":
						help();
				}
			} else {
				run(args);
			}
		}
	}

	@:access(luahscript.LuaPrinter.getDefaultConfigure)
	static function print(args:Array<String>) {
		if(args.length == 0) {
			Sys.println("luahscript: Invalid Content");
			return;
		}
		var path = args.shift();
		var e:LuaExpr = new LuaScript(path).parse();
		var configure:LuaPrinterConfigure = LuaPrinter.getDefaultConfigure();
		var pause:Bool = false;
		var target:String = haxe.io.Path.addTrailingSlash(haxe.io.Path.directory(path)) + "Printer_" + DateTools.format(Date.now(), "%Y-%m-%d_") + haxe.io.Path.withoutDirectory(path);
		for(arg in args) {
			var emm = ~/^\-\-?([\w@]+)$/;
			if(emm.match(arg)) {
				var input = emm.matched(1);
				if(input.toLowerCase() == "no_watermark") {
					configure.waterMark = false;
					continue;
				}
				if(input.toLowerCase() == "formatter") {
					configure.format = true;
					continue;
				}
				var pos = 0;
				while(true) {
					var char = StringTools.fastCodeAt(input, pos++);
					switch(char) {
						case "i".code, "I".code:
							configure.indent = (char == "i".code);
							if(char == "i".code) {
								char = StringTools.fastCodeAt(input, pos++);
								if(char == "@".code) {
									var buf = new StringBuf();
									while(true) {
										char = StringTools.fastCodeAt(input, pos++);
										switch(char) {
											case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: buf.addChar(char);
											case _:
												break;
										}
									}
									configure.indentSpaceChar = Std.parseInt(buf.toString());
								}
								pos--;
							}
						case "s".code, "S".code: configure.semicolon = (char == "s".code);
						case "t".code, "T".code: configure.indentUseTab = (char == "t".code);
						case "f".code, "F".code: configure.focusOneLine = (char == "f".code);
						case "n".code, "N".code: configure.normative = (char == "n".code);
						case _ if(StringTools.isEof(char)): break;
						case _:
							pause = true;
							Sys.println("luahscript: Invalid identifier: " + String.fromCharCode(char));
							break;
					}
				}
			} else {
				if(StringTools.startsWith(arg, "-o=")) {
					target = arg.substr(arg.indexOf("=") + 1);
				}
			}
		}
		if(!pause && e != null) {
			var content = new LuaPrinter(configure).print(e);
			try {
				File.saveContent(target, content);
			} catch(e:Dynamic) {
				Sys.println("luahscript: cannot save file:'" + target + "'");
			}
		}
	}

	static function parse(args:Array<String>) {
		var success:Array<LuaExpr> = [];
		var failed:Array<String> = [];
		for(arg in args) {
			final script = new LuaScript(arg);
			try {
				success.push(script.parse(true));
			} catch(e:ScriptError) {
				failed.push(switch(e) {
					case SEInvalidPath(s, dir): "Invalid Path: cannot open " + "'" + s + "'" + ": " + (dir ? "It's a directory." : "Not Exist this file.");
					case SEError(path, e): "Invalid Syntax: " + path + ":" + LuaPrinter.errorToString(e);
				});
			}
		}
		if(failed.length != 0) Sys.println("Failed Group: {\n  " + failed.join("\n  ") + "\n}");
		Sys.println("Parsing Results......Success=" + success.length + "::Failed=" + failed.length);
	}

	static function run(args:Array<String>) {
		if(args.length == 0) {
			Sys.println("luahscript: Invalid Content");
			return;
		}
		var shc:Bool = false;
		for(arg in args) {
			var emm = ~/^\-\-?([\w@]+)$/;
			if(emm.match(arg)) {
				switch(emm.matched(1).toLowerCase()) {
					case "supporthaxeclass":
						shc = true;
						args.remove(arg);
				}
			}
		}
		var script:LuaScript = new LuaScript(Std.string(args.shift()), shc);
		script.execute(args);
	}

	static function help() {
		var regex = ~/\$\{(\w+)\}/g;
		var helpContent = haxe.Resource.getString("help");
		Sys.println(regex.map(helpContent, function(regex) {
			final input = regex.matched(1);
			if(input == "author") return "VapireMox";
			return Std.string(Reflect.field(haxelib, input));
		}));
	}
}

@:access(luahscript.LuaInterp)
@:access(luahscript.LuaParser)
class LuaScript {
	public var path:String;

	private var interp:LuaInterp;
	private var parser:LuaParser;

	private var haxeClassesInstances:Map<String, haxe.Constraints.Function>;

	var supportHaxeClass:Bool;

	public function new(path:String, supportHaxeClass:Bool = false) {
		this.path = path;
		this.supportHaxeClass = supportHaxeClass;

		haxeClassesInstances = new Map();

		interp = initInterp();
		parser = new LuaParser();
	}

	function initInterp():LuaInterp {
		var interp = new LuaInterp();
		interp.searchPathCallback = function(config:String, module:String, rulePaths:String, ?sep:String, ?rep:String):LuaAndParams {
			module = LuaCheckType.checkString(module);
			final ass:Array<String> = config.split("\n");
			var paths:Array<String> = StringTools.replace(LuaCheckType.checkString(rulePaths), (rep != null ? LuaCheckType.checkString(rep) : ass[2]), StringTools.replace(module, ".", "/")).split(sep != null ? LuaCheckType.checkString(sep) : ass[1]);

			var errm = "";
			for(i=>path in paths) {
				if(FileSystem.exists(path)) return LuaAndParams.fromArray([path]);
				if(i > 0) errm += "\t";
				errm += "no file '" + path + "'";
				if(i < paths.length - 1) errm += "\n";
			}

			return LuaAndParams.fromArray([null, errm]);
		};

		interp.packageAddSearcher(function(packageTable:LuaTable<Dynamic>, module:String):LuaAndParams {
			module = LuaCheckType.checkString(module);
			final re:LuaAndParams = packageTable.get("searchpath")(module, packageTable.get("path"));
			if(re.values.length > 1) return LuaAndParams.fromArray([re.values[1]]);
			else if(re.values.length == 1) {
				final path:String = re.values[0];
				var starCode:Null<String> = try {
					File.getContent(path);
				} catch(e:Dynamic) {
					throw "error loading module '" + module + "' from file '" + path + "':\n\tcannot read " + path + ": Is a directory";
					null;
				}
				if(starCode != null) {
					var e:LuaExpr = null;
					this.run(function() {
						e = this.parser.parseFromString(starCode);
					}, true, "error loading module '" + module + "' from file '" + path + "':\n\t" + path);

					if(e != null) {
						var func:Dynamic = null;
						this.run(function() {
							func = interp.execute(e);
						}, false, "error loading module '" + module + "' from file '" + path + "':\n\t" + path);
						return LuaAndParams.fromArray([func, path]);
					}
				}
			}

			return LuaAndParams.fromArray([null]);
		});
		if(supportHaxeClass) {
			interp.packageAddSearcher(function(packageTable:LuaTable<Dynamic>, module:String):LuaAndParams {
				module = LuaCheckType.checkString(module);
				var cl:Class<Dynamic> = Type.resolveClass(module);
				if(cl != null) {
					final em = module.lastIndexOf(".");
					var cls:String = module.substr(em == -1 ? 0 : em + 1);
					this.registerClass(cls, cl);
					return LuaAndParams.fromArray([Reflect.makeVarArgs(function(args:Array<Dynamic>) {
						return LuaAndParams.fromArray([true]);
					}) , cls]);
				} else {
					return LuaAndParams.fromArray(["no haxe-class '" + module + "'"]);
				}

				return LuaAndParams.fromArray([null]);
			});
		}

		return interp;
	}

	public function registerClass(s:String, cl:Class<Dynamic>) {
		haxeClassesInstances.set(s, Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			args.shift();
			#if neko
			if (Reflect.hasField(cl, "__new__")) {
				return Reflect.callMethod(cl, Reflect.field(cl, "__new__"), args);
			} else {
			#end
				return Type.createInstance(cl, args);
			#if neko
			}
			#end
		}));
		final classTable = new LuaTable<Dynamic>();
		classTable.metaTable = new LuaTable<Dynamic>();
		classTable.metaTable.set("__index", function(t:LuaTable<Dynamic>, index:Dynamic):Dynamic {
			if(index == "new") return haxeClassesInstances.get(s);
			return Reflect.getProperty(cl, index);
		}, false);
		classTable.metaTable.set("__newindex", function(t:LuaTable<Dynamic>, index:Dynamic, value:Dynamic) {
			Reflect.setProperty(cl, index, value);
		});
		this.interp.globals.set(s, classTable);
	}

	public function parse(toThrow:Bool = false):LuaExpr {
		var e:LuaExpr = null;
		if(toThrow) {
			if(!FileSystem.exists(path)) throw SEInvalidPath(path, false);
			if(FileSystem.isDirectory(path)) throw SEInvalidPath(path, true);
			run(() -> {
				e = parser.parseFromString(File.getContent(this.path));
			}, true);
		} else {
			try {
				if(!FileSystem.exists(path)) throw SEInvalidPath(path, false);
				if(FileSystem.isDirectory(path)) throw SEInvalidPath(path, true);
				run(() -> {
					e = parser.parseFromString(File.getContent(this.path));
				}, true);
			} catch(e:ScriptError) {
				Sys.println("luahscript: " + switch(e) {
					case SEInvalidPath(s, dir): "cannot open " + "'" + s + "'" + ": " + (dir ? "It's a directory." : "Not Exist this file.");
					case SEError(path, e): path + ":" + LuaPrinter.errorToString(e);
				});
			}
		}
		return e;
	}

	function run(f:Void->Void, fromParse:Bool = false, ?origin:String) {
		origin = origin ?? this.path;
		try {
			f();
		} catch(e:ScriptError) {
			throw e;
		} catch(e:LuaError) {
			throw SEError(origin, e);
		#if LHST_DEBUG
		} catch(e:haxe.Exception) {
			throw SEError(origin, new LuaError(ECustom(e.message + e.stack), (interp.curExpr == null ? (fromParse ? parser.line : 0) : interp.curExpr.line)));
		#end
		} catch(e:Dynamic) {
			throw SEError(origin, new LuaError(ECustom(Std.string(e)), (interp.curExpr == null ? (fromParse ? parser.line : 0) : interp.curExpr.line)));
		}
	}

	public function execute(args:Array<Dynamic>):Void {
		var e:LuaExpr = parse();
		try {
			if(e != null) {
				run(() -> {
					Reflect.callMethod(null, this.interp.execute(e), args ?? []);
				});
			}
		} catch(e:ScriptError) {
			Sys.println("luahscript: " + switch(e) {
				case SEInvalidPath(s, dir): "cannot open " + "'" + s + "'" + ": " + (dir ? "It's a directory." : "Not Exist this file.");
				case SEError(path, e): path + ":" + LuaPrinter.errorToString(e);
			});
		}
	}
}

enum ScriptError {
	SEInvalidPath(s:String, dir:Bool);
	SEError(path:String, e:LuaError);
}