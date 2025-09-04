package luahscript.lualibs;

import luahscript.LuaInterp;

@:build(luahscript.macros.LuaLibMacro.build())
class LuaStringLib {
	public static inline function lualib_len(str:String):Int {
		return LuaCheckType.checkString(str).length;
	}

	public static function lualib_sub(str:String, a:Int, ?b:Int):String {
		str = LuaCheckType.checkString(str);
		a = realPos(LuaCheckType.checkInteger(a), str.length);
		b = (b == null ? null : realPos(LuaCheckType.checkInteger(b), str.length));
		return str.substring(a, (b == null ? str.length : b + 1));
	}

	public static inline function lualib_reverse(str:String):String {
		final chars = LuaCheckType.checkString(str).split("");
		chars.reverse();
		return chars.join("");
	}

	public static inline function lualib_lower(str:String):String {
		return LuaCheckType.checkString(str).toLowerCase();
	}

	public static inline function lualib_upper(str:String):String {
		return LuaCheckType.checkString(str).toUpperCase();
	}

	public static function lualib_rep(str:String, sc:Int, ?split:String) {
		str = LuaCheckType.checkString(str);
		sc = LuaCheckType.checkInteger(sc);
		split = (split != null ? LuaCheckType.checkString(split) : null);
		if(sc <= 0) return "";
		final buf = new StringBuf();
		for(i in 0...sc) {
			buf.add(str);
			if(split != null && i < sc - 1) {
				buf.add(split);
			}
		}
		return buf.toString();
	}

	@:multiReturn
	public static function lualib_byte(str:String, start:Int = 1, ?end:Int):MultiReturn<haxe.Rest<Int>> {
		str = LuaCheckType.checkString(str);
		start = realPos(LuaCheckType.checkInteger(start), str.length);
		end = (end != null ? realPos(LuaCheckType.checkInteger(end), str.length) : null);
		var chars = readChars(str, start, end);
		return multiReturn(...chars);
	}

	@:multiArgs
	public static function lualib_char(args:Array<Dynamic>) {
		var buf = new StringBuf();
		for(arg in args) {
			buf.add(String.fromCharCode(LuaCheckType.checkInteger(arg)));
		}
		return buf.toString();
	}

	@:multiReturn
	public static function lualib_gsub(str:String, pattern:String, replace:Dynamic, ?n:Int):MultiReturn<String, Int> {
		str = LuaCheckType.checkString(str);
		pattern = LuaCheckType.checkString(pattern);
		n = (n == null ? -1 : n);
		
		var count = 0;
		var result = str;
		var isFunc = Reflect.isFunction(replace);
		
		// Simple implementation without full pattern matching
		while (n == -1 || count < n) {
			var idx = result.indexOf(pattern);
			if (idx == -1) break;
			
			var replacement = isFunc ? 
				Reflect.callMethod(null, replace, [pattern]) : 
				Std.string(replace);
				
			result = result.substring(0, idx) + replacement + result.substring(idx + pattern.length);
			count++;
		}
		
		return multiReturn(result, count);
	}

	@:multiArgs
	public static function lualib_format(args:Array<Dynamic>):String {
		if (args.length == 0) return "";
		var fmt = LuaCheckType.checkString(args[0]);
		var buf = new StringBuf();
		var argIdx = 1;
		var i = 0;

		while (i < fmt.length) {
			var c = fmt.charAt(i);
			if (c == '%') {
				i++;
				if (i >= fmt.length) break;

				var specifier = fmt.charAt(i);
				var arg = args[argIdx++];

				switch (specifier) {
					case 'd', 'i':
						buf.add(LuaCheckType.checkInteger(arg));
					case 'f':
						buf.add(LuaCheckType.checkNumber(arg));
					case 's':
						buf.add(LuaCheckType.checkString(arg));
					case 'c':
						buf.add(String.fromCharCode(LuaCheckType.checkInteger(arg)));
					case '%':
						buf.add('%');
					case 'q':
						var s = LuaCheckType.checkString(arg);
						buf.add('"' + s.split('"').join('\\"') + '"');
					default:
						buf.add('%' + specifier);
				}
			} else {
				buf.add(c);
			}
			i++;
		}
		
		return buf.toString();
	}

	@:multiReturn
	public static function lualib_find(str:String, pattern:String, init:Int = 1, plain:Bool = false):MultiReturn<Null<Int>, Null<Int>> {
		str = LuaCheckType.checkString(str);
		pattern = LuaCheckType.checkString(pattern);
		init = realPos(LuaCheckType.checkInteger(init), str.length);
		
		if (plain) {
			var idx = str.indexOf(pattern, init);
			if (idx == -1) {
				return multiReturn(null, null);
			}
			return multiReturn(idx + 1, idx + pattern.length); // 1-based
		} else {
			// Simple pattern matching (not full Lua pattern support)
			var idx = str.indexOf(pattern, init);
			if (idx == -1) {
				return multiReturn(null, null);
			}
			return multiReturn(idx + 1, idx + pattern.length); // 1-based
		}
	}

	@:multiReturn
	public static function lualib_match(str:String, pattern:String, init:Int = 1):MultiReturn<haxe.Rest<Dynamic>> {
		str = LuaCheckType.checkString(str);
		pattern = LuaCheckType.checkString(pattern);
		init = realPos(LuaCheckType.checkInteger(init), str.length);
		
		// Simple pattern matching (not full Lua pattern support)
		var idx = str.indexOf(pattern, init);
		if (idx == -1) {
			return multiReturn();
		}
		
		// Return the matched substring as the first capture
		return multiReturn(pattern);
	}

	private static function readChars(str:String, start:Int, end:Null<Int>):Array<Int> {
		if (end == null) end = start;
		if (start < 0 || end >= str.length || start > end) return [];
		
		var result = [];
		for (i in start...end + 1) {
			result.push(StringTools.fastCodeAt(str, i));
		}
		return result;
	}

	static inline function realPos(a:Int, len:Int):Int {
		if (a == 0) return 0;
		if (a < 0) return len + a;
		return a - 1; // Convert to 0-based
	}
}
