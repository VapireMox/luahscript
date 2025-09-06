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
    @:multiArgs
    public static function lualib_concat(args:Array<Dynamic>):String {
        if (args.length < 1) throw "concat requires at least 1 argument";
        
        var list = args[0];
        var sep:String = (args.length > 1) ? Std.string(args[1]) : "";
        var i:Int = (args.length > 2) ? LuaCheckType.checkInteger(args[2]) : 1;
        var j:Int = (args.length > 3) ? LuaCheckType.checkInteger(args[3]) : null;
        
        if (Std.isOfType(list, LuaTable)) {
            var table = cast(list, LuaTable<Dynamic>);
            var len = table.length;
            i = realPos(i, len);
            j = (j == null) ? len : realPos(j, len);
            
            i = (i < 0) ? 0 : (i >= len) ? len - 1 : i;
            j = (j < 0) ? 0 : (j >= len) ? len - 1 : j;
            
            if (i > j) return "";
            
            var buf = new StringBuf();
            for (idx in i...j + 1) {
                if (idx > i) buf.add(sep);
                buf.add(Std.string(table.get(idx + 1)));
            }
            return buf.toString();
        } else if (Std.isOfType(list, Array)) {
            var len = list.length;
            i = realPos(i, len);
            j = (j == null) ? len - 1 : realPos(j, len);
            
            i = (i < 0) ? 0 : (i >= len) ? len - 1 : i;
            j = (j < 0) ? 0 : (j >= len) ? len - 1 : j;
            
            if (i > j) return "";
            
            var buf = new StringBuf();
            for (idx in i...j + 1) {
                if (idx > i) buf.add(sep);
                buf.add(Std.string(list[idx]));
            }
            return buf.toString();
        } else {
            throw "bad argument #1 to 'concat' (table expected)";
        }
    }

    // table.insert(list, pos, value) 或 table.insert(list, value)
    @:multiArgs
    public static function lualib_insert(args:Array<Dynamic>):Void {
        if (args.length < 2) throw "insert requires at least 2 arguments";
        
        var list = args[0];
        var value:Dynamic;
        
        if (args.length == 2) {
            value = args[1];
            // 如果是LuaTable，使用push方法
            if (Std.isOfType(list, LuaTable)) {
                cast(list, LuaTable<Dynamic>).push(value);
            } else if (Std.isOfType(list, Array)) {
                list.push(value);
            } else {
                throw "bad argument #1 to 'insert' (table expected)";
            }
        } else {
            var pos:Int = LuaCheckType.checkInteger(args[1]);
            value = args[2];
            
            // 如果是LuaTable，需要实现insert逻辑
            if (Std.isOfType(list, LuaTable)) {
                var table = cast(list, LuaTable<Dynamic>);
                // 简化实现：在指定位置插入
                var len = table.length;
                var idx = realPos(pos, len);
                
                // 将idx位置之后的元素后移
                for (i in len...idx + 1) {
                    table.set(i + 1, table.get(i));
                }
                table.set(idx + 1, value);
            } else if (Std.isOfType(list, Array)) {
                var idx = realPos(pos, list.length);
                list.insert(idx, value);
            } else {
                throw "bad argument #1 to 'insert' (table expected)";
            }
        }
    }

    // table.remove(list, pos?)
    @:multiArgs
    public static function lualib_remove(args:Array<Dynamic>):Dynamic {
        if (args.length < 1) throw "remove requires at least 1 argument";
        
        var list = args[0];
        var pos:Int = (args.length > 1) ? LuaCheckType.checkInteger(args[1]) : null;
        
        if (Std.isOfType(list, LuaTable)) {
            var table = cast(list, LuaTable<Dynamic>);
            var len = table.length;
            pos = (pos == null) ? len : pos;
            var idx = realPos(pos, len);
            idx = (idx < 0) ? 0 : (idx >= len) ? len - 1 : idx;
            
            var value = table.get(idx + 1);
            table.remove(idx + 1);
            return value;
        } else if (Std.isOfType(list, Array)) {
            var len = list.length;
            pos = (pos == null) ? len : pos;
            var idx = realPos(pos, len);
            idx = (idx < 0) ? 0 : (idx >= len) ? len - 1 : idx;
            
            return list.splice(idx, 1)[0];
        } else {
            throw "bad argument #1 to 'remove' (table expected)";
        }
    }

    // table.move(a1, f, e, t, a2?)
    @:multiArgs
    public static function lualib_move(args:Array<Dynamic>):Void {
        if (args.length < 4) throw "move requires at least 4 arguments";
        
        var a1 = args[0];
        var f:Int = LuaCheckType.checkInteger(args[1]);
        var e:Int = LuaCheckType.checkInteger(args[2]);
        var t:Int = LuaCheckType.checkInteger(args[3]);
        var a2:Dynamic = (args.length > 4) ? args[4] : null;
        
        if (Std.isOfType(a1, LuaTable)) {
            var table1 = cast(a1, LuaTable<Dynamic>);
            var len = table1.length;
            f = realPos(f, len);
            e = realPos(e, len);
            
            f = (f < 0) ? 0 : (f >= len) ? len - 1 : f;
            e = (e < 0) ? 0 : (e >= len) ? len - 1 : e;
            
            if (f > e) return;
            
            var table2 = (a2 != null && Std.isOfType(a2, LuaTable)) ? cast(a2, LuaTable<Dynamic>) : table1;
            var count = e - f + 1;
            
            for (i in 0...count) {
                var value = table1.get(f + i + 1);
                table2.set(t + i, value);
            }
        } else if (Std.isOfType(a1, Array)) {
            var len = a1.length;
            f = realPos(f, len);
            e = realPos(e, len);
            t = realPos(t, (a2 != null && Std.isOfType(a2, Array)) ? a2.length : len);
            
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
        } else {
            throw "bad argument #1 to 'move' (table expected)";
        }
    }

    // table.sort(list, comp?)
    @:multiArgs
    public static function lualib_sort(args:Array<Dynamic>):Void {
        if (args.length < 1) throw "sort requires at least 1 argument";
        
        var list = args[0];
        var comp:Dynamic = (args.length > 1) ? args[1] : null;
        
        if (Std.isOfType(list, LuaTable)) {
            var table = cast(list, LuaTable<Dynamic>);
            var len = table.length;
            
            // 提取所有数组部分到临时数组
            var arr:Array<Dynamic> = [];
            for (i in 1...len + 1) {
                arr.push(table.get(i));
            }
            
            // 对临时数组进行排序
            if (comp != null) {
                if (!Reflect.isFunction(comp)) {
                    throw "bad argument #2 to 'sort' (function expected)";
                }
                
                arr.sort(function(a:Dynamic, b:Dynamic):Int {
                    var result = Reflect.callMethod(null, comp, [a, b]);
                    return (result == true) ? -1 : 1;
                });
            } else {
                arr.sort(function(a:Dynamic, b:Dynamic):Int {
                    if (a == b) return 0;
                    return (a < b) ? -1 : 1;
                });
            }
            
            // 将排序后的数组写回表
            for (i in 0...arr.length) {
                table.set(i + 1, arr[i]);
            }
        } else if (Std.isOfType(list, Array)) {
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
        } else {
            throw "bad argument #1 to 'sort' (table expected)";
        }
    }

    // table.pack(...)
    @:multiArgs
    public static function lualib_pack(args:Array<Dynamic>):Dynamic {
        var table = args.copy();
        table.push(args.length); // 设置长度字段
        return table;
    }

    // table.unpack(list, i?, j?)
    @:multiArgs
    public static function lualib_unpack(args:Array<Dynamic>):LuaAndParams {
        if (args.length < 1) throw "unpack requires at least 1 argument";
        
        var list = args[0];
        var i:Int = (args.length > 1) ? LuaCheckType.checkInteger(args[1]) : 1;
        var j:Int = (args.length > 2) ? LuaCheckType.checkInteger(args[2]) : null;
        
        if (Std.isOfType(list, LuaTable)) {
            var table = cast(list, LuaTable<Dynamic>);
            var len = table.length;
            i = realPos(i, len);
            j = (j == null) ? len : realPos(j, len);
            
            // 确保索引在有效范围内
            i = (i < 0) ? 0 : (i >= len) ? len - 1 : i;
            j = (j < 0) ? 0 : (j >= len) ? len - 1 : j;
            
            if (i > j) return LuaAndParams.fromArray([]);
            
            var result = [];
            for (idx in i...j + 1) {
                result.push(table.get(idx + 1));
            }
            return LuaAndParams.fromArray(result);
        } else if (Std.isOfType(list, Array)) {
            var len = list.length;
            i = realPos(i, len);
            j = (j == null) ? len - 1 : realPos(j, len);
            
            // 确保索引在有效范围内
            i = (i < 0) ? 0 : (i >= len) ? len - 1 : i;
            j = (j < 0) ? 0 : (j >= len) ? len - 1 : j;
            
            if (i > j) return LuaAndParams.fromArray([]);
            
            var result = [];
            for (idx in i...j + 1) {
                result.push(list[idx]);
            }
            return LuaAndParams.fromArray(result);
        } else {
            throw "bad argument #1 to 'unpack' (table expected)";
        }
    }
}
