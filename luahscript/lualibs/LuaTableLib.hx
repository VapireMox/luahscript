package luahscript.lualibs;

import luahscript.LuaInterp;
import luahscript.LuaTable;

@:build(luahscript.macros.LuaLibMacro.build())
class LuaTableLib {
    public static function lualib_insert(table:LuaTable<Dynamic>, ?pos:Int, value:Dynamic):Void {
        var t = LuaCheckType.checkTable(table);
        var realLen = 0;
        var i = 1;
        while (true) {
            if (t.get(i) == null) {
                break;
            }
            realLen = i;
            i++;
        }
        if (pos == null) {
            t.set(realLen + 1, value);
            return;
        }
        pos = LuaCheckType.checkInteger(pos);
        if (pos < 1) pos = 1;

        i = realLen;
        while (i >= pos) {
            t.set(i + 1, t.get(i));
            i--;
        }
        t.set(pos, value);
    }

    public static function lualib_remove(table:LuaTable<Dynamic>, ?pos:Int):Dynamic {
        var t = LuaCheckType.checkTable(table);
        
        var realLen = 0;
        var i = 1;
        while (true) {
            if (t.get(i) == null) {
                break;
            }
            realLen = i;
            i++;
        }
        if (realLen == 0) return null;

        pos = (pos == null) ? realLen : LuaCheckType.checkInteger(pos);
        if (pos < 1 || pos > realLen) return null;
        
        var removed = t.get(pos);
        
        i = pos;
        while (i < realLen) {
            t.set(i, t.get(i + 1));
            i++;
        }
        t.set(realLen, null);
        
        return removed;
    }

    public static function lualib_concat(table:LuaTable<Dynamic>, ?sep:String, ?i:Int, ?j:Int):String {
        var t = LuaCheckType.checkTable(table);
        sep = (sep != null) ? LuaCheckType.checkString(sep) : "";
        var start = (i != null) ? LuaCheckType.checkInteger(i) : 1;
        var end = (j != null) ? LuaCheckType.checkInteger(j) : t.length;
        var buf = new StringBuf();
        for (idx in start...end + 1) {
            if (idx > start) buf.add(sep);
            var val = t.get(idx);
            if (val != null) {
                buf.add(Std.string(val));
            }
        }
        return buf.toString();
    }

    @:multiReturn
    public static function lualib_unpack(table:LuaTable<Dynamic>, ?start:Int, ?end:Int):MultiReturn<haxe.Rest<Dynamic>> {
        var t = LuaCheckType.checkTable(table);
        start = (start != null) ? LuaCheckType.checkInteger(start) : 1;
        end = (end != null) ? LuaCheckType.checkInteger(end) : t.length;
        var result = [];
        for (i in start...end + 1) {
            result.push(t.get(i));
        }
        return multiReturn(...result);
    }

    public static function lualib_pack(...args:Dynamic):LuaTable<Dynamic> {
        var t = new LuaTable();
        var n = 0;
        for (arg in args) {
            n++;
            t.set(n, arg);
        }
        t.set("n", n);
        return t;
    }

    public static function lualib_sort(table:LuaTable<Dynamic>, ?comp:Dynamic->Dynamic->Bool):Void {
        var t = LuaCheckType.checkTable(table);
        var arr = [];
        var len = t.length;
        for (i in 1...len + 1) {
            arr.push(t.get(i));
        }
        if (comp != null && Reflect.isFunction(comp)) {
            arr.sort((a, b) -> comp(a, b) ? -1 : 1);
        } else {
            arr.sort((a, b) -> Reflect.compare(Std.string(a), Std.string(b)));
        }
        for (i in 0...arr.length) {
            t.set(i + 1, arr[i]);
        }
    }
}
