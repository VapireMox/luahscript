package;

import luahscript.LuaInterp;
import luahscript.LuaParser;
import luahscript.LuaPrinter;
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
					case SEError(e): "Invalid Syntax: " + script.path + ":" + LuaPrinter.errorToString(e);
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
		new LuaScript(Std.string(args.shift())).execute(args);
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

	public function new(path:String) {
		this.path = path;

		interp = new LuaInterp();
		parser = new LuaParser();
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
					case SEError(e): path + ":" + LuaPrinter.errorToString(e);
				});
			}
		}
		return e;
	}

	function run(f:Void->Void, fromParse:Bool = false) {
		try {
			f();
		} catch(e:LuaError) {
			throw SEError(e);
		} catch(e:Dynamic) {
			throw SEError(new LuaError(ECustom(Std.string(e)), (interp.curExpr == null ? (fromParse ? parser.line : 0) : interp.curExpr.line)));
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
				case SEError(e): path + ":" + LuaPrinter.errorToString(e);
			});
		}
	}
}

enum ScriptError {
	SEInvalidPath(s:String, dir:Bool);
	SEError(e:LuaError);
}