# Luahscript

Luahscript is a Haxe library that uses hscript to parse and execute Lua scripts. The project is still under development, but already supports compilation on multiple platforms.

## Features

- Uses hscript to parse Lua scripts
- Supports compilation on multiple platforms: C++, Neko, Interp, JavaScript, and more
- Provides complete Lua syntax support, including variables, control structures, functions, and tables
- Supports metatables and metamethods
- Offers error handling and debugging capabilities

## Installation

Install Luahscript using haxelib:

```bash
haxelib install luahscript
```
---

If you need to experience new features, you can download lib in github:

```bash
haxelib git luahscript https://github.com/VapireMox/luahscript
```

## Quick Start

Here's a simple example showing how to parse and execute a Lua script:

```haxe
import lhscript.LHScript;

class Main {
    public static function main() {
        // Define a simple Lua script
        var luaScript = '
            local function greet(name)
                return "Hello, " .. name .. "!"
            end
            
            return greet("World")
        ';
        
        // Create an interpreter and execute the script
        var interp = new LHScript(expr);
        interp.execute();
        
        // Execute the returned function and trace the result
        // NOTE: The function from Lua are usually 'luahscript.LuaAndParams'. if want to obtain its value, call the "values" field, pls.
        trace(result("Hello Lua!", "5.4")); // Output: Hello, World!
    }
}
```

## Documentation

- [Complete Documentation](https://github.com/VapireMox/luahscript/blob/master/DOCUMENTATION.md)

## Usage Examples

For more usage examples, please refer to the [tests directory](./tests).(No completion!)

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a Pull Request

## License

Luahscript is released under the Apache 2.0 License. See the LICENSE file for details.
