# Luahscript Documentation

## Overview

Luahscript is a Haxe library that uses hscript to parse and execute Lua scripts. It provides a way to integrate Lua scripting capabilities into Haxe applications, allowing developers to leverage Lua's simplicity and flexibility within their Haxe projects.

The library currently supports compilation on multiple platforms including C++, Neko, JavaScript, and more, making it versatile for various development environments.

## Features

- Lua script parsing and execution
- Support for core Lua syntax including variables, control structures, functions, and tables
- Cross-platform compatibility
- Integration with Haxe applications
- Support for metatables and metamethods
- Error handling and debugging capabilities

## Installation

To use Luahscript in your Haxe project, add it to your dependencies using haxelib:

```bash
haxelib install luahscript
```

Then include it in your Haxe project:

```haxe
import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;
```

## Quick Start

Here's a simple example of how to parse and execute a Lua script:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
    public static function main() {
        // Define a simple Lua script
        var luaScript = '
            local function greet(name)
                return "Hello, " .. name .. "!"
            end
            
            return greet("World")
        ';
        
        // Parse the Lua script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        
        // Create an interpreter and execute the script
        var interp = new LuaInterp();
        var result = interp.execute(expr);
        
        // Execute the returned function and trace the result
        trace(result()); // Output: Hello, World!
    }
}
```

## Tutorial

### 1. Basic Lua Script Execution

Let's start with a basic example that demonstrates how to execute a Lua script and access its variables and functions:

```haxe
import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class BasicExample {
    public static function main() {
        // Define a Lua script with variables and functions
        var luaScript = '
            -- Variables
            local message = "Hello from Lua!"
            local number = 42
            
            -- Function
            function add(a, b)
                return a + b
            end
            
            -- Table
            person = {
                name = "John",
                age = 30,
                greet = function(self)
                    return "Hi, I\'m " .. self.name
                end
            }
        ';

        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);

        // Access Lua variables and functions from Haxe, but they need save in "globals"
        var addFunc = interp.globals.get("add");
        var person = interp.globals.get("person");

        // Call Lua functions
        trace(addFunc(5, 3)); // Output: 8
        trace(person.greet(person)); // Output: Hi, I'm John
    }
}
```

### 2. Passing Data Between Haxe and Lua

This example shows how to pass data from Haxe to Lua and vice versa:

```haxe
import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class DataExchangeExample {
    public static function main() {
        // Define a Lua script that processes Haxe data
        var luaScript = '
            -- Function to process a Haxe array
            function processArray(arr)
                local sum = 0
                for i, v in ipairs(arr) do
                    sum = sum + v
                end
                return sum
            end
            
            -- Function to create a Lua table
            function createTable(name, values)
                local result = {
                    name = name,
                    count = #values,
                    sum = 0
                }
                
                for i, v in ipairs(values) do
                    result.sum = result.sum + v
                end
                
                return result
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Get the Lua functions
        var processArray = interp.globals.get("processArray");
        var createTable = interp.globals.get("createTable");
        
        // on haxe, array need to convert luahscript.LuaTable
        var convert = luahscript.LuaTable.fromArray([1, 2, 3, 4, 5]);
        var sum = processArray(haxeArray);
        trace("Sum of array: " + sum); // Output: Sum of array: 15

        var table = createTable("Numbers", haxeArray).values[0];
        // on haxe, you can use "LuaTable.get & LuaTable.set" to "get & set" for lua
        trace("Table name: " + table.get("name")); // Output: Table name: Numbers
        trace("Table count: " + table.get("count")); // Output: Table count: 5
        trace("Table sum: " + table.get("sum")); // Output: Table sum: 15
    }
}
```

### 3. Error Handling

This example demonstrates how to handle errors in Lua scripts:

```haxe
import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class ErrorHandlingExample {
    public static function main() {
        // Define a Lua script with potential errors
        var luaScript = '
            function divide(a, b)
                if b == 0 then
                    error("Division by zero!")
                end
                return a / b
            end
            
            function safeDivide(a, b)
                local status, result = pcall(function()
                    return divide(a, b)
                end)
                
                if status then
                    return result
                else
                    return "Error: " .. result
                end
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Get the Lua functions
        var divide = interp.globals.get("divide");
        var safeDivide = interp.globals.get("safeDivide");
        
        try {
            // This will throw an error
            trace(divide(10, 0));
        } catch (e:Dynamic) {
            trace("Caught error: " + e); // Output: Caught error: Division by zero!
        }
        
        // This will handle the error gracefully
        trace(safeDivide(10, 0)); // Output: Error: Division by zero!
        trace(safeDivide(10, 2)); // Output: 5.0
    }
}
```

### 4. Working with Metatables

This example shows how to use Lua metatables with Luahscript:

```haxe
import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class MetatableExample {
    public static function main() {
        // Define a Lua script with metatables
        var luaScript = '
            -- Create a vector table
            function createVector(x, y)
                local vector = { x = x, y = y }
                
                -- Set up metatable
                setmetatable(vector, {
                    __add = function(a, b)
                        return createVector(a.x + b.x, a.y + b.y)
                    end,
                    __sub = function(a, b)
                        return createVector(a.x - b.x, a.y - b.y)
                    end,
                    __mul = function(a, scalar)
                        return createVector(a.x * scalar, a.y * scalar)
                    end,
                    __tostring = function(v)
                        return "(" .. v.x .. ", " .. v.y .. ")"
                    end
                })
                
                return vector
            end
            
            -- Function to demonstrate vector operations
            function vectorDemo()
                local v1 = createVector(1, 2)
                local v2 = createVector(3, 4)
                
                local v3 = v1 + v2
                local v4 = v1 - v2
                local v5 = v1 * 3
                
                return {
                    v1 = tostring(v1),
                    v2 = tostring(v2),
                    v3 = tostring(v3),
                    v4 = tostring(v4),
                    v5 = tostring(v5)
                }
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Get the Lua function
        var vectorDemo = interp.locals.get("vectorDemo");
        
        // Call the function and display the results
        var results = vectorDemo();
        trace("v1: " + results.values[0].get("v1")); // Output: v1: (1, 2)
        trace("v2: " + results.values[0].get("v2")); // Output: v2: (3, 4)
        trace("v1 + v2: " + results.values[0].get("v3")); // Output: v1 + v2: (4, 6)
        trace("v1 - v2: " + results.values[0].get("v4")); // Output: v1 - v2: (-2, -2)
        trace("v1 * 3: " + results.values[0].get("v5")); // Output: v1 * 3: (3, 6)
    }
}
```

## API Reference

### LuaParser

The `LuaParser` class is responsible for parsing Lua scripts into expression trees that can be executed by the interpreter.

#### Methods

- `new()`: Creates a new LuaParser instance.
- `parseFromString(content:String):LuaExpr`: Parses a Lua script from a string and returns an expression tree.

### LuaInterp

The `LuaInterp` class executes the parsed Lua expressions and provides access to Lua variables and functions.

#### Properties

- `globals:Map<String, Dynamic>`: A map of global variables in the Lua environment.

#### Methods

- `new()`: Creates a new LuaInterp instance.
- `execute(expr:LuaExpr):Dynamic`: Executes a parsed Lua expression and returns the result.
- `resolve(id:String):Dynamic`: Resolves a variable or function by name from the Lua environment.

### LuaExpr

Represents a parsed Lua expression. This is typically created by the LuaParser and consumed by the LuaInterp.

## Supported Lua Features

Luahscript supports a subset of Lua features, including:

- Variables and data types (nil, boolean, number, string, function, table)
- Arithmetic operators (+, -, *, /, //, %, ^, #)
- Comparison operators (==, ~=, <, >, <=, >=)
- Logical operators (and, or, not)
- Control structures (if, while, repeat, for)
- Functions and closures
- Tables and metatables
- Basic error handling

## About on "require"
- In Lua，"require" function is used to import modules (Lua files) and allows access to modify the global variables of the modules.
- But in this lib, it only supports expressions, and you need to manually set the "require" function in "globals"

## Limitations

While Luahscript provides a good subset of Lua functionality, there are some limitations:

- Not all standard Lua libraries are available
- Some advanced Lua features may not be fully supported
- Performance may not match that of a native Lua implementation

## Examples

The project includes a test.lua file that demonstrates various Lua features. You can find it in the root directory of the project. This test script covers:

- Variables and basic data types
- Tables (both array-like and dictionary-like)
- Control structures (if, while, repeat, for)
- Functions (including variadic functions)
- Metatables and metamethods
- Error handling with pcall
- Closures

## Contributing

If you'd like to contribute to the Luahscript project, please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Credits

如下👎