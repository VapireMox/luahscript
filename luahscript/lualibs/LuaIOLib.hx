package luahscript.lualibs;

import luahscript.LuaInterp;
#if (sys)
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.io.Process;
import sys.FileSystem;
import sys.io.FileSeek; // For io.seek
#end
@:build(luahscript.macros.LuaLibMacro.build())
class LuaIOLib {
    public static inline function lualib_open(file:String, mode:String):String
    {
        var filse:String = "";
        var filePath = LuaCheckType.checkString(file);
        
        switch (mode) {
            case 'r':
                filse = sys.io.File.getContent(filePath);
            case 'rb':
                var fileInput:sys.io.FileInput = sys.io.File.read(filePath, true);
                filse = fileInput.readAll().toString();
                fileInput.close();
            case 'a':
                var fileOutput:sys.io.FileOutput = sys.io.File.append(filePath);
                filse = Std.string(fileOutput); 
            default:
                throw "Unsupported file mode: " + mode; //lol
        }
        
        return filse;
    }
}
