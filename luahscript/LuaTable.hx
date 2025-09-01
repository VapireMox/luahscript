package luahscript;

import luahscript.LuaInterp;

/**
 * 希望各位以我为戒，不要过度使用傻逼dickseek
 */
@:allow(luahscript.LuaTableIpairsIterator)
@:allow(luahscript.LuaInterp)
class LuaTable<V> {
	public var length(get, never):Int;
	inline function get_length():Int {
		return _keys.length;
	}

	public var metaTable:LuaTable<Dynamic>;

	private var nextIndex:Int;
	var _keys:Array<Dynamic>;
	var _values:Array<V>;

	public function new() {
		nextIndex = 1;
		_keys = [];
		_values = [];
	}

	/**
	 * 设置值，可以是任意类型的键或数组索引
	 */
	public function set(key:Dynamic, value:V, toOverride:Bool = true):Void {
		if(_keys.contains(key)) {
			if(!toOverride) return;
			final index = _keys.indexOf(key);
			_values[index] = value;
			return;
		}
		if(key == nextIndex) {
			_keys.insert(nextIndex - 1, key);
			_values.insert(nextIndex - 1, value);
			nextIndex++;
		} else {
			_keys.push(key);
			_values.push(value);
		}

		fixKey();
	}

	public function push(value:V):Int {
		_keys.insert(nextIndex - 1, nextIndex);
		_values.insert(nextIndex - 1, value);
		final result = nextIndex++;
		fixKey();
		return result;
	}

	public function remove(key:Dynamic):Void {
		if(_keys.contains(key)) {
			final index = _keys.indexOf(key);
			_keys.remove(key);
			_values.remove(_values[index]);
			if(LuaCheckType.isInteger(key)) {
				var int:Int = cast key;
				if(int < nextIndex) {
					for(i in 0...nextIndex - int - 1) {
						_keys[index + i] -= 1;
					}
					nextIndex--;
				}
			}
		}
	}

	inline function fixKey() {
		if(_keys.contains(nextIndex)) {
			final index = _keys.indexOf(nextIndex);
			final value = _values[index];
			_keys.remove(nextIndex);
			_values.remove(value);
			_keys.insert(index - 1, nextIndex);
			_values.insert(index - 1, value);
			nextIndex++;
		}
	}

	public inline function keyExists(key:Dynamic):Bool {
		return _keys.contains(key);
	}

	/**
	 * 获取值
	 */
	public function get(key:Dynamic):Null<V> {
		return _values[_keys.indexOf(key)];
	}

	/**
	 * 迭代所有键
	 */
	public function keys():Iterator<Dynamic> {
		return _keys.iterator();
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
	var table:LuaTable<T>;
	var length:Int;
	var current:Int = 1;

	public inline function new(table:LuaTable<T>) {
		this.length = table.nextIndex;
		this.table = table;
	}

	public inline function hasNext() {
		return current < length;
	}

	public inline function next() {
		return {value: table.get(current), key: current++};
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