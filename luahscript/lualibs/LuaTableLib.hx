package luahscript.lualibs;

import luahscript.LuaTable;
import luahscript.LuaInterp;

/*
 * unfinished: move, sort
*/
@:build(luahscript.macros.LuaLibMacro.build())
class LuaTableLib {
	public static function lualib_concat(table:LuaTable<Dynamic>, ?sep:Dynamic, ?i:Int = 1, ?j:Int):String {
		var buf:StringBuf = new StringBuf();

		for(k in LuaCheckType.checkInteger(i)...(j == null ? getTableIndex(LuaCheckType.checkTable(table)) : LuaCheckType.checkInteger(j)) + 1) {
			final value:Dynamic = LuaCheckType.checkNotSpecialValue(table.get(k));
			buf.add(value);
			if(k < getTableIndex(table) && sep != null) {
				buf.add(LuaCheckType.checkNotSpecialValue(sep));
			}
		}
		return buf.toString();
	}

	public static function lualib_insert(table:LuaTable<Dynamic>, blur:Dynamic, ?value:Dynamic):Void {
		table = LuaCheckType.checkTable(table);
		var pos:Int = (value != null ? LuaCheckType.checkInteger(blur) : getTableIndex(table) + 1);
		table.insert(pos, value != null ? value : blur);
	}

	@:multiArgs
	public static inline function lualib_pack(args:Array<Dynamic>):LuaTable<Dynamic> {
		var t:LuaTable<Dynamic> = LuaTable.fromArray(args);
		t.set("n", t.nextIndex - 1);
		return t;
	}

	@:multiReturn
	public static function lualib_unpack(table:LuaTable<Dynamic>, i:Int = 1, ?j:Int):MultiReturn<haxe.Rest<Dynamic>> {
		table = LuaCheckType.checkTable(table);
		var arr:Array<Dynamic> = [];
		for(k in LuaCheckType.checkInteger(i)...(j != null ? LuaCheckType.checkInteger(j) : getTableIndex(table)) + 1) {
			arr.push(table.get(k));
		}
		return multiReturn(...arr);
	}

	public static inline function lualib_remove(table:LuaTable<Dynamic>, ?pos:Int):Dynamic {
		table = LuaCheckType.checkTable(table);
		var pos = (pos != null ? LuaCheckType.checkInteger(pos) : getTableIndex(table));
		if(pos > table.nextIndex || pos < 1) throw "position out of bounds";
		if(pos == table.nextIndex) return null;
		return table.remove(pos);
	}

	public static function lualib_move(table:LuaTable<Dynamic>, s:Int, e:Int, pos:Int, ?target:LuaTable<Dynamic>):LuaTable<Dynamic> {
		LuaCheckType.checkTable(table);
		s = LuaCheckType.checkInteger(s);
		e = LuaCheckType.checkInteger(e);
		pos = LuaCheckType.checkInteger(pos);
		if (target != null) {
			LuaCheckType.checkTable(target);
		}

		var sourceTable = table;
		var targetTableForMove = (target != null) ? target : table;

		if (s > e) {
			return targetTableForMove;
		}

		if (s < 1) s = 1;
		if (pos < 1) pos = 1;

		var moveCount = e - s + 1;

		if (sourceTable == targetTableForMove) {
			if (pos > s) {
				var srcIdx = e;
				var destIdx = pos + moveCount - 1;
				for (i in 0...moveCount) {
					targetTableForMove.set(destIdx - i, sourceTable.get(srcIdx - i));
				}
			} else if (pos < s) {
				var srcIdx = s;
				var destIdx = pos;
				for (i in 0...moveCount) {
					targetTableForMove.set(destIdx + i, sourceTable.get(srcIdx + i));
				}
			}
		} else {
			var srcIdx = s;
			var destIdx = pos;
			for (i in 0...moveCount) {
				targetTableForMove.set(destIdx + i, sourceTable.get(srcIdx + i));
			}
		}
		
		return targetTableForMove;
	}

	public static function lualib_sort(table:LuaTable<Dynamic>, comp:Dynamic):Void {
		LuaCheckType.checkTable(table);
		
		var arr:Array<Dynamic> = [];
		for (i in 1...table.nextIndex) {
			arr.push(table.get(i));
		}

		if (comp != null) {
			try {
				arr.sort(function(a:Dynamic, b:Dynamic):Int {
					var luaComparisonResult:Dynamic = Reflect.callMethod(null, comp, [a, b]);
					
					if (luaComparisonResult == null) {
						return 1;
					}
					
					var haxeBoolResult:Bool = cast luaComparisonResult;
					return haxeBoolResult ? -1 : 1;
				});
			} catch (e:Dynamic) {
				throw "Invalid comparator function or execution error in table.sort: " + Std.string(e);
			}
		} else {
			arr.sort(function(a:Dynamic, b:Dynamic):Int {
				if (a == null && b == null) return 0;
				if (a == null) return -1; 
				if (b == null) return 1;

				var typeA = Type.typeof(a);
				var typeB = Type.typeof(b);

				if (typeA != typeB) {
					return Reflect.compare(Type.getClassName(Type.getClass(a)), Type.getClassName(Type.getClass(b)));
				}

				switch (typeA) {
					case TInt, TFloat: return Reflect.compare(a, b);
					case TClass(String): return Reflect.compare(a, b);
					case TBool: return Reflect.compare(a, b);
					default: return Reflect.compare(Std.string(a), Std.string(b));
				}
			});
		}

		for (i in 0...arr.length) {
			table.set(i + 1, arr[i]);
		}
	}

	static inline function getTableIndex(table:LuaTable<Dynamic>):Int {
		return table.nextIndex - 1;
	}
}
