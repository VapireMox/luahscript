package luahscript;

class LuaNumIterator {
	var min:Float;
	var max:Float;
	var step:Float;

	public inline function new(min:Float, max:Float, ?step:Float = 1) {
		this.min = min;
		this.max = max;
		this.step = step;
	}

	public inline function hasNext() {
		return (this.step >= 0 ? min <= max : min >= max);
	}

	public inline function next() {
		final old = min;
		min += this.step;
		return old;
	}
}
