package luahscript;

class LuaAndParams {
	public var values:Array<Dynamic>;

	public function new() {
		values = [];
	}

	public static function fromArray(array:Array<Dynamic>):LuaAndParams {
		var lap = new LuaAndParams();
		lap.values = array;
		return lap;
	}

	public inline function push(value:Dynamic):Int {
		return values.push(value);
	}

	public function concat(sb:LuaAndParams):LuaAndParams {
		this.values = this.values.concat(sb.values);
		return this;
	}

	public function toString() {
		return values.join("\t");
	}
}