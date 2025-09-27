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
import luahscript.LuaInterp;
import luahscript.LuaParser;
import luahscript.exprs.LuaExpr;
import luahscript.LuaAndParams;

class Main {
	public static function main() {
		var input:String = 'local apple, banana = ...; return apple .. " and " .. banana';

		var interp = new LuaInterp();
		var parser = new LuaParser();

		final e:LuaExpr = parser.parseFromString(input);
		// Get A Function By Default.
		final func = interp.execute(e);

		// You can input paramters for function and will return result what the class "LuaAndParams" by default.
		final result:LuaAndParams = cast func("apple", "banana");
		trace(result.values[0]); // apple and banana
	}
}

```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a Pull Request

## License

Luahscript is released under the Apache 2.0 License. See the LICENSE file for details.
