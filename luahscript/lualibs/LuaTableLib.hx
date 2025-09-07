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

	@:noCompletion public static function lualib_move(table:LuaTable<Dynamic>, s:Int, e:Int, pos:Int, ?target:LuaTable<Dynamic>):LuaTable<Dynamic> {
		throw "'table.move' is unfinished";
		return null;
	}

	@:noCompletion public static function lualib_sort(table:LuaTable<Dynamic>, comp:Dynamic):Void {
		throw "'table.sort' is unfinished";
	}

	static inline function getTableIndex(table:LuaTable<Dynamic>):Int {
		return table.nextIndex - 1;
	}
}