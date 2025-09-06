package luahscript.lualibs;

import luahscript.LuaInterp;
import luahscript.LuaTable;

@:build(luahscript.macros.LuaLibMacro.build())
class LuaTableLib {
    public static inline function lualib_insert(table:LuaTable<Dynamic>, ?pos:Int, value:Dynamic):Void {
        var t = LuaCheckType.checkTable(table);
        var len = getArrayLength(t);

        if (pos == null) {
            t.set(len + 1, value);
            return;
        }

        pos = LuaCheckType.checkInteger(pos);
        if (pos < 1) pos = 1;

        for (i in new luahscript.LuaNumIterator(len, pos - 1, -1)) {
            t.set(i + 1, t.get(i));
        }
        t.set(pos, value);
    }

    public static inline function lualib_remove(table:LuaTable<Dynamic>, ?pos:Int):Dynamic {
        var t = LuaCheckType.checkTable(table);
        var len = getArrayLength(t);
        if (len == 0) return null;

        pos = (pos == null) ? len : LuaCheckType.checkInteger(pos);
        if (pos < 1 || pos > len) return null;

        var removed = t.get(pos);
        
        for (i in new luahscript.LuaNumIterator(pos, len - 1)) {
            t.set(i, t.get(i + 1));
        }
        t.set(len, null);
        return removed;
    }

    public static inline function lualib_concat(table:LuaTable<Dynamic>, ?sep:String, ?i:Int, ?j:Int):String {
        var t = LuaCheckType.checkTable(table);
        sep = (sep != null) ? LuaCheckType.checkString(sep) : "";
        var len = getArrayLength(t);
        var start = (i != null) ? LuaCheckType.checkInteger(i) : 1;
        var end = (j != null) ? LuaCheckType.checkInteger(j) : len;
        var buf = new StringBuf();
        for (idx in start...end + 1) {
            if (idx > start) buf.add(sep);
            var val = t.get(idx);
            if (val != null) buf.add(Std.string(val));
        }
        return buf.toString();
    }

    @:multiReturn
    public static inline function lualib_unpack(table:LuaTable<Dynamic>, ?start:Int, ?end:Int):MultiReturn<haxe.Rest<Dynamic>> {
        var t = LuaCheckType.checkTable(table);
        var len = getArrayLength(t);
        start = (start != null) ? LuaCheckType.checkInteger(start) : 1;
        end = (end != null) ? LuaCheckType.checkInteger(end) : len;
        var result = [];
        for (i in start...end + 1) {
            result.push(t.get(i));
        }
        return multiReturn(...result);
    }

    public static inline function lualib_pack(...args:Dynamic):LuaTable<Dynamic> {
        var t = new LuaTable();
        var n = 0;
        for (arg in args) {
            n++;
            t.set(n, arg);
        }
        t.set("n", n);
        return t;
    }

    public static inline function lualib_sort(table:LuaTable<Dynamic>, ?comp:Dynamic->Dynamic->Bool):Void {
        var t = LuaCheckType.checkTable(table);
        var arr = [];
        var len = getArrayLength(t);
        
        for (i in new luahscript.LuaNumIterator(1, len)) {
            arr.push(t.get(i));
        }
        
        if (comp != null && Reflect.isFunction(comp)) {
            arr.sort((a, b) -> comp(a, b) ? -1 : 1);
        } else {
            arr.sort((a, b) -> Reflect.compare(Std.string(a), Std.string(b)));
        }
        
        for (i in new luahscript.LuaNumIterator(1, len)) {
            t.set(Std.int(i), arr[Std.int(i) - 1]);
        }
    }

    static inline function getArrayLength(t:LuaTable<Dynamic>):Int {
        var i = 1;
        while (true) {
            if (t.get(i) == null) break;
            i++;
        }
        return i - 1;
    }

    static inline function hasValue(t:LuaTable<Dynamic>, i:Int):Bool {
        var v = t.get(i);
        return v != null;
    }
}
