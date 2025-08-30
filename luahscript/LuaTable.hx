package luahscript;

/**
 * 由我们弱智且傻逼的Dickseek生成（但还是得改）
 * 我也不是不想整，主要不是懒，而是“确实懒”
 */
@:allow(luahscript.LuaTableIpairsIterator)
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