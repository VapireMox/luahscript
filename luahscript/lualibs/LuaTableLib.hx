package luahscript.lualibs;

import luahscript.LuaInterp;
// 你永远可以相信智谱清言GLM4.5模型 永远不要相信deepseek.v3.1
@:build(luahscript.macros.LuaLibMacro.build())
class LuaTableLib {
    // 辅助函数：将 Lua 1-based 索引转换为 Haxe 0-based 索引
    private static function realPos(pos:Int, len:Int):Int {
        if (pos == 0) return 0;
        if (pos < 0) return len + pos;
        return pos - 1; // 转换为 0-based
    }

    // table.concat(list, sep?, i?, j?)
    public static function lualib_concat(list:Array<Dynamic>, ?sep:String = "", ?i:Int = 1, ?j:Int):String {
        if (list == null) return "";
        
        var len = list.length;
        i = realPos(LuaCheckType.checkInteger(i), len);
        j = (j == null) ? len - 1 : realPos(LuaCheckType.checkInteger(j), len);
        
        i = (i < 0) ? 0 : (i >= len) ? len - 1 : i;
        j = (j < 0) ? 0 : (j >= len) ? len - 1 : j;
        
        if (i > j) return "";
        
        var buf = new StringBuf();
        for (idx in i...j + 1) {
            if (idx > i) buf.add(sep);
            buf.add(Std.string(list[idx]));
        }
        return buf.toString();
    }

    // table.insert(list, pos, value) 或 table.insert(list, value)
    @:multiArgs
    public static function lualib_insert(args:Array<Dynamic>):Void {
        if (args.length < 2) throw "insert requires at least 2 arguments";
        
        var list = args[0];
        if (!Std.is(list, Array)) throw "bad argument #1 to 'insert' (table expected)";
        
        var pos:Int, value:Dynamic;
        if (args.length == 2) {
            value = args[1];
            list.push(value);
        } else {
            pos = LuaCheckType.checkInteger(args[1]);
            value = args[2];
            var idx = realPos(pos, list.length);
            list.insert(idx, value);
        }
    }

    // table.remove(list, pos?)
    public static function lualib_remove(list:Array<Dynamic>, ?pos:Int):Dynamic {
        if (list == null) return null;
        
        var len = list.length;
        pos = (pos == null) ? len : LuaCheckType.checkInteger(pos);
        var idx = realPos(pos, len);
        
        idx = (idx < 0) ? 0 : (idx >= len) ? len - 1 : idx;
        
        return list.splice(idx, 1)[0];
    }

    // table.move(a1, f, e, t, a2?)
    public static function lualib_move(a1:Array<Dynamic>, f:Int, e:Int, t:Int, ?a2:Array<Dynamic>):Void {
        if (a1 == null) return;
        
        var len = a1.length;
        f = realPos(LuaCheckType.checkInteger(f), len);
        e = realPos(LuaCheckType.checkInteger(e), len);
        t = realPos(LuaCheckType.checkInteger(t), (a2 != null) ? a2.length : len);
        
        f = (f < 0) ? 0 : (f >= len) ? len - 1 : f;
        e = (e < 0) ? 0 : (e >= len) ? len - 1 : e;
        
        if (f > e) return;
        
        a2 = (a2 != null) ? a2 : a1;
        var count = e - f + 1;
        
        while (a2.length < t + count) {
            a2.push(null);
        }
        
        for (i in 0...count) {
            a2[t + i] = a1[f + i];
        }
    }

    // table.sort(list, comp?)
    public static function lualib_sort(list:Array<Dynamic>, ?comp:Dynamic):Void {
        if (list == null) return;
        
        if (comp != null) {
            if (!Reflect.isFunction(comp)) {
                throw "bad argument #2 to 'sort' (function expected)";
            }
            
            list.sort(function(a:Dynamic, b:Dynamic):Int {
                var result = Reflect.callMethod(null, comp, [a, b]);
                return (result == true) ? -1 : 1;
            });
        } else {
            list.sort(function(a:Dynamic, b:Dynamic):Int {
                if (a == b) return 0;
                return (a < b) ? -1 : 1;
            });
        }
    }

    // table.pack(...)
    @:multiArgs
    public static function lualib_pack(args:Array<Dynamic>):Dynamic {
        var table = args.copy();
        table["n"] = args.length; // 设置长度字段
        return table;
    }

    // table.unpack(list, i?, j?)
    @:multiReturn
    public static function lualib_unpack(list:Array<Dynamic>, ?i:Int = 1, ?j:Int):MultiReturn<haxe.Rest<Dynamic>> {
        if (list == null) return multiReturn();
        
        var len = list.length;
        i = realPos(LuaCheckType.checkInteger(i), len);
        j = (j == null) ? len - 1 : realPos(LuaCheckType.checkInteger(j), len);
        
        // 确保索引在有效范围内
        i = (i < 0) ? 0 : (i >= len) ? len - 1 : i;
        j = (j < 0) ? 0 : (j >= len) ? len - 1 : j;
        
        if (i > j) return multiReturn();
        
        var result = [];
        for (idx in i...j + 1) {
            result.push(list[idx]);
        }
        return multiReturn(...result);
    }
}
