package luahscript;

import luahscript.LuaInterp;

/**
 * 由我们弱智且傻逼的Dickseek生成（但还是得改）
 * 我也不是不想整，主要不是懒，而是“确实懒”
 */
@:allow(luahscript.LuaTableIpairsIterator)
@:allow(luahscript.LuaInterp)
class LuaTable<V> {
	public var length(get, never):Int;
	inline function get_length():Int {
		return array.length + mapLength;
	}

	public var metaTable:LuaTable<Dynamic>;

	var map:Map<Dynamic, V>;
	var array:Array<V>;

	@:noCompletion private var nextIndex:Int;

	private var mapLength:Int;

	public function new() {
		map = new Map<Dynamic, V>();
		array = [];
	}

	/**
	 * 设置值，可以是任意类型的键或数组索引
	 */
	public function set(key:Dynamic, value:V, toOverride:Bool = true):Void {
		if (key is Int) {
			var idx:Int = cast key;
			if (idx > 0) {
				removeMap(idx);
				if(idx <= array.length + 1) {
					if(toOverride || !(idx < array.length)) array[idx] = value;
					return;
				}
			}
		}
		// 对于非正整数键并且未超过array的长度，使用Map存储
		setMap(key, value);
	}

	inline function setMap(key:Dynamic, value:V):Void {
		if(!map.exists(key)) mapLength++;
		map.set(key, value);
	}

	inline function removeMap(key:Dynamic):Void {
		if(map.exists(key)) {
			mapLength--;
			map.remove(key);
		}
	}

	public inline function keyExists(key:Dynamic):Bool {
		return map.exists(key);
	}

	/**
	 * 获取值
	 */
	public function get(key:Dynamic):Null<V> {
		if (key is Int) {
			var idx:Int = cast key;
			if (idx > 0 && idx <= array.length) {
				return array[idx];
			}
		}
		return map.get(key);
	}

	/**
	 * 迭代所有键
	 */
	public function keys():Iterator<Dynamic> {
		var keysList:Array<Dynamic> = [];

		// 添加数组索引作为键
		for (i in 1...array.length) {
			keysList.push(i);
		}

		// 添加map中的键
		for (key in map.keys()) {
			keysList.push(key);
		}

		return keysList.iterator();
	}
	
	/**
	 * 转换为字符串表示
	 */
	public function toString():String {
		return Std.string(__tostring(this));
	}

	//+
	private function __add(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__add")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__add"), [t, r]);
			}
		}
		return null;
	}

	//-
	private function __sub(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__sub")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__sub"), [t, r]);
			}
		}
		return null;
	}

	//*
	private function __mul(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__mul")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__mul"), [t, r]);
			}
		}
		return null;
	}

	///
	private function __div(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__div")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__div"), [t, r]);
			}
		}
		return null;
	}

	////
	private function __idiv(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__idiv")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__idiv"), [t, r]);
			}
		}
		return null;
	}

	//%
	private function __mod(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__mod")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__mod"), [t, r]);
			}
		}
		return null;
	}

	//^
	private function __pow(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__pow")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__pow"), [t, r]);
			}
		}
		return null;
	}

	//-
	private function __unm(t:LuaTable<Dynamic>):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__unm")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__unm"), [t]);
			}
		}
		return null;
	}

	//...
	private function __concat(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__concat")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__concat"), [t, r]);
			}
		}
		return null;
	}

	//#
	private function __len(t:LuaTable<Dynamic>):Dynamic {
		if(metaTable != null) {
			trace("ahhhh");
			if(LuaCheckType.checkType(metaTable.get("__len")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__len"), [t]);
			}
		}
		return null;
	}

	//==
	private function __eq(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__eq")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__eq"), [t, r]);
			}
		}
		return null;
	}

	//<
	private function __lt(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__lt")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__lt"), [t, r]);
			}
		}
		return null;
	}

	//<=
	private function __le(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__le")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__le"), [t, r]);
			}
		}
		return null;
	}

	private function __read(t:LuaTable<Dynamic>, r:Dynamic):Dynamic {
		if(metaTable != null) {
			final sb = LuaCheckType.checkType(metaTable.get("__index"));
			if(sb == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__index"), [t, r]);
			} else if(sb == TTABLE) {
				return cast(t, LuaTable<Dynamic>).get(r);
			}
		}
		return this.get(r);
	}

	private function __write(t:LuaTable<Dynamic>, r:Dynamic, value:Dynamic):Void {
		if(metaTable != null) {
			final sb = LuaCheckType.checkType(metaTable.get("__newindex"));
			if(sb == TFUNCTION) {
				Reflect.callMethod(t, metaTable.get("__newindex"), [t, r, value]);
				return;
			} else if(sb == TTABLE) {
				return cast(t, LuaTable<Dynamic>).set(r, value);
			}
		}
		return this.set(r, value);
	}

	private function __call(t:LuaTable<Dynamic>, args:Array<Dynamic>):Dynamic {
		if(metaTable != null) {
			final sb = LuaCheckType.checkType(metaTable.get("__call"));
			if(sb == TFUNCTION) {
				args = args ?? [];
				return Reflect.callMethod(t, metaTable.get("__call"), cast([t], Array<Dynamic>).concat(args));
			} else if(sb == TTABLE) {
				return cast(sb, LuaTable<Dynamic>).get("__call");
			}
		}
		return null;
	}

	private function __tostring(t:LuaTable<Dynamic>):String {
		if(metaTable != null) {
			if(LuaCheckType.checkType(metaTable.get("__tostring")) == TFUNCTION) {
				return Reflect.callMethod(t, metaTable.get("__tostring"), [t]);
			}
		}
		return "table";
	}
}

class LuaTableIpairsIterator<T> {
	var array:Array<T>;
	var current:Int = 1;

	public inline function new(table:LuaTable<T>) {
		this.array = table.array;
	}

	public inline function hasNext() {
		return current < array.length;
	}

	public inline function next() {
		return {value: array[current], key: current++};
	}
}

class LuaTablePairsIterator<T> {
	var keys:Iterator<T>;
	var _table:LuaTable<T>;

	public inline function new(table:LuaTable<T>) {
		this.keys = table.keys();
		this._table = table;
	}

	/**
		See `Iterator.hasNext`
	**/
	public inline function hasNext():Bool {
		return keys.hasNext();
	}

	/**
		See `Iterator.next`
	**/
	public inline function next() {
		var key = keys.next();
		return {value: _table.get(key), key: key};
	}
}