package luahscript.lualibs;

import luahscript.LuaInterp;

#if (sys)
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
#end

@:build(luahscript.macros.LuaLibMacro.build())
class LuaOSLib {
	public static inline function lualib_clock():Float {
		#if (sys)
		return Sys.cpuTime();
		#elseif js
		if (untyped __js__("typeof performance !== 'undefined' && performance.now")) {
			return untyped __js__("performance.now()") / 1000;
		}
		return Date.now().getTime() / 1000;
		#else
		// Fallback for other platforms
		return Date.now().getTime() / 1000;
		#end
	}

	public static function lualib_date(?format:String, ?time:Float):String {
		format = LuaCheckType.checkString(format);
		var t:Float = (time != null) ? LuaCheckType.checkNumber(time) : Date.now().getTime() / 1000;
		var date = Date.fromTime(t * 1000);

		if (format == null) {
			return StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2) + "/" +
					StringTools.lpad(Std.string(date.getDate()), "0", 2) + "/" +
					Std.string(date.getFullYear()).substr(2) + " " +
					StringTools.lpad(Std.string(date.getHours()), "0", 2) + ":" +
					StringTools.lpad(Std.string(date.getMinutes()), "0", 2) + ":" +
					StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
		} else if (format == "!*t" || format == "*t") {
			return "table:year=" + date.getFullYear() + 
					",month=" + (date.getMonth() + 1) + 
					",day=" + date.getDate() + 
					",hour=" + date.getHours() + 
					",min=" + date.getMinutes() + 
					",sec=" + date.getSeconds() + 
					",wday=" + (date.getDay() == 0 ? 7 : date.getDay()) + 
					",yday=" + getDayOfYear(date) + 
					",isdst=";
		} else {
			var formattedDate = "";
			var i = 0;
			while (i < format.length) {
				var c = format.charAt(i);
				if (c == '%') {
					i++;
					if (i >= format.length) break;
					var specifier = format.charAt(i);
					switch (specifier) {
						case 'a': formattedDate += getShortDayName(date.getDay());
						case 'A': formattedDate += getFullDayName(date.getDay());
						case 'b': formattedDate += getShortMonthName(date.getMonth());
						case 'B': formattedDate += getFullMonthName(date.getMonth());
						case 'c': formattedDate += date.toString();
						case 'd': formattedDate += StringTools.lpad(Std.string(date.getDate()), "0", 2);
						case 'H': formattedDate += StringTools.lpad(Std.string(date.getHours()), "0", 2);
						case 'I': formattedDate += StringTools.lpad(Std.string(date.getHours() % 12 == 0 ? 12 : date.getHours() % 12), "0", 2);
						case 'j': formattedDate += StringTools.lpad(Std.string(getDayOfYear(date)), "0", 3);
						case 'm': formattedDate += StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2);
						case 'M': formattedDate += StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
						case 'p': formattedDate += (date.getHours() < 12) ? "AM" : "PM";
						case 'S': formattedDate += StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
						case 'U': formattedDate += StringTools.lpad(Std.string(getWeekOfYearSunday(date)), "0", 2);
						case 'w': formattedDate += Std.string(date.getDay() == 0 ? 7 : date.getDay());
						case 'W': formattedDate += StringTools.lpad(Std.string(getWeekOfYearMonday(date)), "0", 2);
						case 'x': formattedDate += StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2) + "/" + StringTools.lpad(Std.string(date.getDate()), "0", 2) + "/" + Std.string(date.getFullYear()).substr(2);
						case 'X': formattedDate += StringTools.lpad(Std.string(date.getHours()), "0", 2) + ":" + StringTools.lpad(Std.string(date.getMinutes()), "0", 2) + ":" + StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
						case 'y': formattedDate += Std.string(date.getFullYear()).substr(2);
						case 'Y': formattedDate += Std.string(date.getFullYear());
						case '%': formattedDate += '%';
						default: formattedDate += '%' + specifier;
					}
				} else {
					formattedDate += c;
				}
				i++;
			}
			return formattedDate;
		}
	}

	public static function lualib_difftime(t2:Float, t1:Float):Float {
		return LuaCheckType.checkNumber(t2) - LuaCheckType.checkNumber(t1);
	}

	public static function lualib_execute(command:String):Int {
		#if (sys)
		try {
			// Sys.command is simpler and directly returns exit code.
			// new Process() allows more control if needed (e.g. reading stdout/stderr)
			return Sys.command(LuaCheckType.checkString(command));
		} catch (e:Dynamic) {
			return -1; // Indicate an error, e.g. command not found
		}
		#elseif js
		#if nodejs
		try {
			var child_process = untyped __js__("require('child_process')");
			var result = untyped child_process.execSync(LuaCheckType.checkString(command), { encoding: 'utf8', stdio: 'pipe' });
			// execSync throws on non-zero exit, so if we reach here, it was successful.
			// To get exit code, we might need spawn or exec with a callback.
			// For simplicity, assume success if no exception.
			return 0; 
		} catch(e:Dynamic) {
			var exitCode = Reflect.field(e, "status");
			return (exitCode != null && Std.isOfType(exitCode, Int)) ? exitCode : -1;
		}
		#else
		// Plain JS (browser): cannot execute, return error code.
		trace("Warning: os.execute is not supported in this environment.");
		return -1;
		#end
		#else
		trace("Warning: os.execute is not supported on this platform.");
		return -1;
		#end
	}

	public static function lualib_exit(?code:Int = 0):Void {
		#if (sys)
		Sys.exit(LuaCheckType.checkInteger(code));
		#elseif js
		// In browser JS, Sys.exit might not be available or behave as expected.
		// Throwing an error can stop execution but isn't a true exit.
		#if nodejs
		untyped __js__("process.exit(" + LuaCheckType.checkInteger(code) + ")");
		#else
		code = LuaCheckType.checkInteger(code);
		throw "os.exit called with code " + code + ". In browser, this throws an error instead of exiting.";
		#end
		#else
		throw "os.exit is not supported on this platform.";
		#end
	}

	public static function lualib_getenv(varname:String):Null<String> {
		varname = LuaCheckType.checkString(varname);
		#if sys
		return Sys.getEnv(varname);
		#elseif js
		#if nodejs
		return untyped __js__("process.env[" + varname + "]");
		#else
		// Browser JS: no direct access to environment variables for security.
		trace("Warning: os.getenv is not supported in this environment.");
		return null;
		#end
		#else
		trace("Warning: os.getenv is not supported on this platform.");
		return null;
		#end
	}

	public static function lualib_remove(?filename:String):Bool {
		if (filename == null) return false;
		filename = LuaCheckType.checkString(filename);
		#if sys
		try {
			if (FileSystem.exists(filename)) {
				if (FileSystem.isDirectory(filename)) {
					FileSystem.deleteDirectory(filename);
				} else {
					FileSystem.deleteFile(filename);
				}
				return true;
			}
			return false; 
		} catch (e:Dynamic) {
			return false; 
		}
		#elseif js
		// JS (browser or Node.js) cannot directly delete files without specific APIs (e.g. Node.js 'fs')
		#if nodejs
		try {
			var fs = untyped __js__("require('fs')");
			var stats = untyped fs.statSync(filename);
			if (stats.isDirectory()) {
				untyped fs.rmdirSync(filename);
			} else {
				untyped fs.unlinkSync(filename);
			}
			return true;
		} catch(e:Dynamic) {
			return false;
		}
		#else
		trace("Warning: os.remove is not supported in this environment.");
		return false;
		#end
		#else
		trace("Warning: os.remove is not supported on this platform.");
		return false;
		#end
	}

	public static function lualib_rename(oldname:String, newname:String):Bool {
		oldname = LuaCheckType.checkString(oldname);
		newname = LuaCheckType.checkString(newname);
		#if sys 
		try {
			if (FileSystem.exists(oldname)) {
				FileSystem.rename(oldname, newname);
				return true;
			}
			return false; 
		} catch (e:Dynamic) {
			return false; 
		}
		#elseif js
		#if nodejs
		try {
			var fs = untyped __js__("require('fs')");
			untyped fs.renameSync(oldname, newname);
			return true;
		} catch(e:Dynamic) {
			return false;
		}
		#else
		trace("Warning: os.rename is not supported in this environment.");
		return false;
		#end
		#else
		trace("Warning: os.rename is not supported on this platform.");
		return false;
		#end
	}

	public static function lualib_setlocale(locale:String, ?category:String = "all"):String {
		trace("Warning: os.setlocale is not fully implemented and may behave differently or not at all on this platform.");
		// Returning "C" as a default, as it's often the minimal locale.
		return "C"; 
	}

	public static function lualib_time(?table:LuaTable<Dynamic>):Float {
		if (table == null) {
			// Called with no arguments, return current timestamp
			return Date.now().getTime() / 1000;
		}
		table = LuaCheckType.checkTable(table);

		var year = table.get("year");
		var month = table.get("month"); // Lua month is 1-12
		var day = table.get("day");
		var hour = table.get("hour");
		var min = table.get("min");
		var sec = table.get("sec");

		if (year == null || month == null || day == null) {
			throw "os.time: table must have year, month, and day fields";
		}
		
		var date = new Date(year, Std.int(month) - 1, day, hour != null ? hour : 0, min != null ? min : 0, sec != null ? sec : 0);
		return date.getTime() / 1000;
	}

	public static function lualib_tmpname():String {
		#if sys
		var tempDir = "";
		#if (cpp || cs || java || php || python || hl) // Targets known to have Sys.tempDir()
			tempDir = "/tmp";
		#elseif neko
			#if windows
			tempDir = Sys.getEnv("TEMP") != null ? Sys.getEnv("TEMP") : "C:\\TEMP";
			#elseif (linux || mac)
			tempDir = "/tmp";
			#else
			tempDir = "."; // Fallback to current directory
			#end
		#elseif nodejs // Node.js specific
			var os = untyped __js__("require('os')");
			tempDir = untyped os.tmpdir();
		#else
			#if windows
			tempDir = Sys.getEnv("TEMP") != null ? Sys.getEnv("TEMP") : "C:\\TEMP";
			#elseif (linux || mac)
			tempDir = "/tmp";
			#else
			tempDir = "."; // Fallback to current directory
			#end
		#end

		var uniqueId = Std.int(Date.now().getTime());
		// Ensure path separator is correct for the platform
		var pathSep = #if windows "\\" #else "/" #end;
		var tempFileName = tempDir + pathSep + "luah_tmp_" + uniqueId + "_" + Std.random(1000000);
		return tempFileName;
		#elseif js
			#if nodejs
			var os = untyped __js__("require('os')");
			return untyped os.tmpdir() + "/luah_tmp_" + Date.now().getTime() + "_" + Math.floor(Math.random() * 1000000);
			#else
			// Browser JS: no standard way to get a temporary file path.
			trace("Warning: os.tmpname in a browser environment returns a name, not a usable path.");
			return "luah_tmp_" + Date.now().getTime() + "_" + Math.floor(Math.random() * 1000000);
			#end
		#else
			trace("Warning: os.tmpname is not fully supported on this platform, returning a generated name.");
			return "luah_tmp_" + Date.now().getTime() + "_" + Std.random(1000000);
		#end
	}

	private static function getShortDayName(day:Int):String {
		return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][day];
	}

	private static function getFullDayName(day:Int):String {
		return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day];
	}

	private static function getShortMonthName(month:Int):String {
		return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][month];
	}

	private static function getFullMonthName(month:Int):String {
		return ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month];
	}

	private static function getDayOfYear(date:Date):Int {
		var startOfYear = new Date(date.getFullYear(), 0, 1, 0, 0, 0);
		var diff = date.getTime() - startOfYear.getTime();
		return Math.floor(diff / (1000 * 60 * 60 * 24)) + 1;
	}

	private static function getWeekOfYearSunday(date:Date):Int {
		var firstDayOfYear = new Date(date.getFullYear(), 0, 1, 0, 0, 0);
		var firstSunday = firstDayOfYear.getDay();
		var dayOfYear = getDayOfYear(date);
		
		if (firstSunday == 0) { 
			return Math.floor((dayOfYear - 1) / 7);
		} else {
			return Math.floor((dayOfYear - (7 - firstSunday)) / 7);
		}
	}

	private static function getWeekOfYearMonday(date:Date):Int {
		var firstDayOfYear = new Date(date.getFullYear(), 0, 1, 0, 0, 0);
		var firstMonday = (8 - firstDayOfYear.getDay()) % 7; 
		if (firstMonday == 0) firstMonday = 7; 

		var dayOfYear = getDayOfYear(date);

		if (dayOfYear < firstMonday) {
			return 0; 
		}
		
		return Math.floor((dayOfYear - firstMonday) / 7) + 1;
	}
}

