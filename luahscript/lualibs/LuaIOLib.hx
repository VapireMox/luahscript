package luahscript.lualibs;
import luahscript.LuaInterp;
#if (sys)
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.io.Process;
import sys.FileSystem;
import sys.io.FileSeek;
#end
@:build(luahscript.macros.LuaLibMacro.build())
class LuaIOLib {
	private static var fileHandles:Map<String, Dynamic> = new Map<String, Dynamic>();
	private static var nextHandleId:Int = 0;

	private static function bytesToString(bytes:haxe.io.Bytes):String {
		var buf = new StringBuf();
		for (i in 0...bytes.length) {
			buf.addChar(bytes.get(i));
		}
		return buf.toString();
	}

	public static inline function lualib_open(file:String, mode:String):String {
		var filePath = LuaCheckType.checkString(file);
		var handleId = "FILE_HANDLE_" + (nextHandleId++);
		
		switch (mode) {
			case 'r': 
				var fileInput:FileInput = File.read(filePath, false);
				fileHandles.set(handleId, fileInput);
				
			case 'rb':
				var fileInput:FileInput = File.read(filePath, true);
				fileHandles.set(handleId, fileInput);
				
			case 'w':
				var fileOutput:FileOutput = File.write(filePath);
				fileHandles.set(handleId, fileOutput);
				
			case 'wb':
				var fileOutput:FileOutput = File.write(filePath);
				fileHandles.set(handleId, fileOutput);
				
			case 'a': 
				var fileOutput:FileOutput = File.append(filePath);
				fileHandles.set(handleId, fileOutput);
				
			default:
				throw "Unsupported file mode: " + mode;
		}
		
		return handleId;
	}

	public static inline function lualib_close(handle:String):Void {
		if (!fileHandles.exists(handle)) {
			throw "Invalid file handle: " + handle;
		}
		
		var fileObj = fileHandles.get(handle);
		
		if (Std.isOfType(fileObj, FileInput)) {
			var file:FileInput = cast fileObj;
			file.close();
		} else if (Std.isOfType(fileObj, FileOutput)) {
			var file:FileOutput = cast fileObj;
			file.close();
		} else {
			throw "Invalid file object type: " + handle;
		}
		
		fileHandles.remove(handle);
	}

	public static function lualib_read(handle:String, ?format:String):String {
		if (handle == null || handle == "") {
			throw "Invalid file handle: empty or null";
		}
		
		if (!fileHandles.exists(handle)) {
			throw "Invalid file handle: " + handle;
		}
		
		var fileObj = fileHandles.get(handle);
		if (!Std.isOfType(fileObj, FileInput)) {
			throw "File not open for reading: " + handle;
		}
		
		var file:FileInput = cast fileObj;
		
		if (format == null) format = "*l";
		
		switch (format) {
			case "*a": 
				try {
					var bytes = file.readAll();
					return bytesToString(bytes);
				} catch (e:haxe.io.Eof) {
					return "";
				}
				
			case "*l":
				try {
					var line = file.readLine();
					return line;
				} catch (e:haxe.io.Eof) {
					return "";
				}
				
			case "*n":
				try {
					var line = file.readLine();
					var num = LuaCheckType.checkNumber(line);
					return Std.string(num);
				} catch (e:haxe.io.Eof) {
					return "";
				}
				
			default: 
				try {
					var numBytesFloat = LuaCheckType.checkNumber(format);
					if (numBytesFloat == null) {
						throw "Invalid read format: " + format;
					}
					
					var numBytes = Std.int(numBytesFloat);
					if (numBytes < 0) {
						throw "Byte count cannot be negative: " + numBytes;
					}
					
					var bytes = haxe.io.Bytes.alloc(numBytes);
					var bytesRead = file.readBytes(bytes, 0, numBytes);
					
					return bytesRead == 0 ? "" : bytesToString(bytes.sub(0, bytesRead));
				} catch (e:haxe.io.Eof) {
					return "";
				}
		}
	}

	public static function lualib_write(handle:String, data:Dynamic):Void {
		if (!fileHandles.exists(handle)) {
			throw "Invalid file handle: " + handle;
		}
		
		var fileObj = fileHandles.get(handle);
		
		var file:FileOutput = cast fileObj;
		
		if (Std.isOfType(data, String)) {
			file.writeString(cast data);
		} else if (Std.isOfType(data, haxe.io.Bytes)) {
			file.writeBytes(cast data, 0, cast(data, haxe.io.Bytes).length);
		} else {
			throw "Invalid data type for writing: " + Type.getClassName(Type.getClass(data));
		}
	}

	public static function lualib_flush(handle:String):Void {
		if (!fileHandles.exists(handle)) {
			throw "Invalid file handle: " + handle;
		}
		
		var fileObj = fileHandles.get(handle);
		if (!Std.isOfType(fileObj, FileOutput)) {
			throw "File not open for writing: " + handle;
		}
		
		var file:FileOutput = cast fileObj;
		file.flush();
	}

	public static function lualib_seek(handle:String, whence:String = "cur", offset:Int = 0):Int {
		if (!fileHandles.exists(handle)) {
			throw "Invalid file handle: " + handle;
		}
		
		var fileObj = fileHandles.get(handle);
		var seekMode:FileSeek;
		
		switch (whence) {
			case "set": seekMode = SeekBegin;
			case "cur": seekMode = SeekCur;
			case "end": seekMode = SeekEnd;
			default: throw "Invalid seek mode: " + whence;
		}
		
		if (Std.isOfType(fileObj, FileInput)) {
			var file:FileInput = cast fileObj;
			file.seek(offset, seekMode);
			return file.tell();
		} else if (Std.isOfType(fileObj, FileOutput)) {
			var file:FileOutput = cast fileObj;
			file.seek(offset, seekMode);
			return file.tell();
		} else {
			throw "Invalid file object type: " + handle;
		}
	}

	public static function lualib_exists(path:String):Bool {
		var filePath = LuaCheckType.checkString(path);
		return FileSystem.exists(filePath);
	}

	public static function lualib_size(path:String):Int {
		var filePath = LuaCheckType.checkString(path);
		if (!FileSystem.exists(filePath)) {
			throw "File not found: " + filePath;
		}
		return FileSystem.stat(filePath).size;
	}

	//未实现
	public static function lualib_input(?handle:Dynamic):Void {

	}

	public static function lualib_output(?handle:Dynamic):Void {

	}
}
