package luahscript.lualibs;

import luahscript.LuaInterp;

@:build(luahscript.macros.LuaLibMacro.build())
class LuaMathLib {
	public static var lualib_pi(get, never):Float;
	static inline function get_lualib_pi():Float {
		return Math.PI;
	}

	public static var lualib_huge(get, never):Float;
	static inline function get_lualib_huge():Float {
		return Math.POSITIVE_INFINITY;
	}

	public static var lualib_maxinteger(get, never):Int;
	public static function get_lualib_maxinteger():Int {
		return 2147483647;
	}

	public static var lualib_mininteger(get, never):Int;
	public static function get_lualib_mininteger():Int {
		return -2147483648;
	}

	public static inline function lualib_abs(a:Float):Float {
		return Math.abs(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_sin(a:Float):Float {
		return Math.sin(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_cos(a:Float):Float {
		return Math.cos(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_tan(a:Float):Float {
		return Math.tan(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_asin(a:Float):Float {
		return Math.asin(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_acos(a:Float):Float {
		return Math.acos(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_atan(a:Float):Float {
		return Math.atan(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_floor(a:Float):Int {
		return Math.floor(LuaCheckType.checkNumber(a));
	}

	public static function lualib_toint(a:Float):Null<Int> {
		if(LuaCheckType.checkType(a) == TNUMBER) {
			final na:Int = Std.int(LuaCheckType.checkNumber(a));
			if(na == a) return na;
		}
		throw "value is not convertible to integer";
		return null;
	}

	public static inline function lualib_ceil(a:Float):Int {
		return Math.ceil(a);
	}

	public static function lualib_fmod(a:Float, b:Float):Float {
		if(b == 0) throw "division by zero";
		final chu:Float = LuaCheckType.checkNumber(a) / LuaCheckType.checkNumber(b);
		return a - (chu >= 0 ? Math.floor(chu) : Math.ceil(chu)) * b;
	}

	@:multiReturn
	public static function lualib_modf(a:Float):MultiReturn<Int, Float> {
		if(LuaCheckType.isInteger(a)) return multiReturn(a, 0);
		final int:Int = (LuaCheckType.checkNumber(a) >= 0 ? Math.floor(a) : Math.ceil(a));
		var frac:Float = a - int;
		if(Math.abs(frac) < 1e-15) frac = 0;
		return multiReturn(int, frac);
	}

	public static inline function lualib_sqrt(a:Float):Float {
		return Math.sqrt(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_log(a:Float, ?b:Float):Float {
		return if(b != null) Math.log(LuaCheckType.checkNumber(a)) / Math.log(LuaCheckType.checkNumber(b)) else Math.log(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_exp(a:Float):Float {
		return Math.exp(LuaCheckType.checkNumber(a));
	}

	public static inline function lualib_deg(a:Float):Float {
		return LuaCheckType.checkNumber(a) * (180 / Math.PI);
	}

	public static inline function lualib_rad(a:Float):Float {
		return LuaCheckType.checkNumber(a) * (Math.PI / 180);
	}

	@:multiArgs
	public static function lualib_min(args:Array<Dynamic>):Null<Float> {
		if(args.length > 0) {
			var min:Float = LuaCheckType.checkNumber(args.shift());
			var i = -1;
			while(i++ < args.length - 1) {
				min = Math.min(LuaCheckType.checkNumber(args[i]), min);
			}
			return min;
		}
		return null;
	}

	@:multiArgs
	public static function lualib_max(args:Array<Dynamic>):Null<Float> {
		if(args.length > 0) {
			var max:Float = LuaCheckType.checkNumber(args.shift());
			var i = -1;
			while(i++ < args.length - 1) {
				max = Math.max(LuaCheckType.checkNumber(args[i]), max);
			}
			return max;
		}
		return null;
	}

	public static function lualib_type(a:Float):String {
		return LuaCheckType.isInteger(LuaCheckType.checkNumber(a)) ? "int" : "float";
	}

	public static function lualib_random(a:Null<Int>, b:Null<Int>):Float {
		if(a == null && b == null) return Math.random();
		LuaCheckType.checkInteger(a);
		LuaCheckType.checkInteger(b);
		return (a >= b ? b : a) + Std.random(Std.int(Math.abs(b - a)));
	}

	public static inline function lualib_pow(a:Float, b:Float) {
		return Math.pow(LuaCheckType.checkNumber(a), LuaCheckType.checkNumber(b));
	}
}