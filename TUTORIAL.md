# Luahscript Tutorial

## Introduction

This tutorial will guide you through the basics of using Luahscript, a Haxe library that allows you to parse and execute Lua scripts within your Haxe applications. By the end of this tutorial, you'll be able to integrate Lua scripting into your Haxe projects effectively.

## Prerequisites

Before starting this tutorial, make sure you have:

- Basic knowledge of Haxe programming
- Haxe development environment set up
- Luahscript library installed (`haxelib install luahscript`)

## Tutorial Contents

1. [Setting Up Your Project](#1-setting-up-your-project)
2. [Your First Lua Script](#2-your-first-lua-script)
3. [Working with Variables and Functions](#3-working-with-variables-and-functions)
4. [Tables in Lua](#4-tables-in-lua)
5. [Control Structures](#5-control-structures)
6. [Error Handling](#6-error-handling)
7. [Advanced Features: Metatables](#7-advanced-features-metatables)
8. [Integrating Lua with Haxe](#8-integrating-lua-with-haxe)

---

## 1. Setting Up Your Project

First, let's create a new Haxe project and set up the necessary dependencies.

### Step 1: Create a New Project

Create a new directory for your project and initialize it:

```bash
mkdir luahscript-tutorial
cd luahscript-tutorial
```

### Step 2: Create a Project File

Create a `build.hxml` file with the following content:

```hxml
-cp src
-main Main
-neko output.n
--next
-cmd neko output.n
```

### Step 3: Set Up the Source Directory

Create a `src` directory for your source code:

```bash
mkdir src
```

### Step 4: Add Luahscript Dependency

Make sure you have Luahscript installed:

```bash
haxelib install luahscript
```

Now your project is set up and ready to use Luahscript!

---

## 2. Your First Lua Script

Let's start with a simple example that executes a basic Lua script.

### Step 1: Create the Main Haxe File

Create a file `src/Main.hx` with the following content:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class Main {
    public static function main() {
        // Define a simple Lua script
        var luaScript = '
            local message = "Hello, World!"
            print(message)
            
            -- Return a function
            return function()
                return "Script executed successfully!"
            end
        ';
        
        // Parse the Lua script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        
        // Create an interpreter and execute the script
        var interp = new LuaInterp();
        var result = interp.execute(expr);
        
        // Execute the returned function
        trace(result()); // Output: Script executed successfully!
    }
}
```

### Step 2: Run the Project

Execute the following command in your terminal:

```bash
haxe build.hxml
```

You should see the output:

```
Hello, World!
Script executed successfully!
```

### Explanation

1. We defined a simple Lua script that creates a variable `message` and prints it.
2. The script also returns a function that we can call from Haxe.
3. We used `LuaParser` to parse the script into an expression tree.
4. We used `LuaInterp` to execute the parsed expression.
5. Finally, we called the returned function and traced its result.

---

## 3. Working with Variables and Functions

Now let's explore how to work with variables and functions in Lua scripts and interact with them from Haxe.

### Step 1: Create a New Example

Create a file `src/VariablesAndFunctions.hx` with the following content:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class VariablesAndFunctions {
    public static function main() {
        // Define a Lua script with variables and functions
        var luaScript = '
            -- Global variables
            globalVar = "I am global"
            
            -- Local variables
            local localVar = "I am local"
            
            -- Function with parameters
            function add(a, b)
                return a + b
            end
            
            -- Function with multiple return values
            function getMinMax(...)
                local args = {...}
                if #args == 0 then
                    return nil, nil
                end
                
                local min = args[1]
                local max = args[1]
                
                for i = 2, #args do
                    if args[i] < min then
                        min = args[i]
                    end
                    if args[i] > max then
                        max = args[i]
                    end
                end
                
                return min, max
            end
            
            -- Function with closure
            function createCounter()
                local count = 0
                return function()
                    count = count + 1
                    return count
                end
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Access global variables
        trace("Global variable: " + interp.resolve("globalVar"));
        
        // Try to access local variable (this will be null)
        trace("Local variable: " + interp.resolve("localVar"));
        
        // Call Lua functions from Haxe
        var addFunc = interp.resolve("add");
        trace("5 + 3 = " + addFunc(5, 3));
        
        var getMinMaxFunc = interp.resolve("getMinMax");
        var result = getMinMaxFunc(10, 5, 20, 15);
        trace("Min: " + result.values[0] + ", Max: " + result.values[1]);
        
        // Work with closures
        var createCounterFunc = interp.resolve("createCounter");
        var counter = createCounterFunc();
        trace("Counter: " + counter());
        trace("Counter: " + counter());
        trace("Counter: " + counter());
    }
}
```

### Step 2: Update the Build File

Modify your `build.hxml` file to use this new class:

```hxml
-cp src
-main VariablesAndFunctions
-neko output.n
--next
-cmd neko output.n
```

### Step 3: Run the Project

Execute the following command:

```bash
haxe build.hxml
```

You should see output similar to:

```
Global variable: I am global
Local variable: null
5 + 3 = 8
Min: 5, Max: 20
Counter: 1
Counter: 2
Counter: 3
```

### Explanation

1. We defined global and local variables in the Lua script. Note that only global variables are accessible from Haxe.
2. We created several functions:
   - `add`: A simple function that adds two numbers
   - `getMinMax`: A function with variadic arguments that returns multiple values
   - `createCounter`: A function that creates a closure
3. We accessed these functions from Haxe using `interp.resolve()`.
4. For functions that return multiple values, the result is wrapped in a special object with a `values` array.
5. We demonstrated how closures work by creating a counter function that maintains its state between calls.

---

## 4. Tables in Lua

Tables are a fundamental data structure in Lua. Let's explore how to work with them in Luahscript.

### Step 1: Create a New Example

Create a file `src/TablesExample.hx` with the following content:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class TablesExample {
    public static function main() {
        // Define a Lua script with tables
        var luaScript = '
            -- Array-like table
            local fruits = {"apple", "banana", "orange"}
            
            -- Dictionary-like table
            local person = {
                name = "John",
                age = 30,
                city = "New York"
            }
            
            -- Mixed table
            local mixed = {
                "first",
                ["key"] = "value",
                [2] = "second",
                [true] = "boolean value"
            }
            
            -- Function to work with tables
            function processTable(t)
                local result = {}
                
                if type(t) == "table" then
                    for k, v in pairs(t) do
                        result[k] = tostring(v) .. " processed"
                    end
                end
                
                return result
            end
            
            -- Function to create a table with methods
            function createCircle(radius)
                local circle = {radius = radius}
                
                function circle:getArea()
                    return math.pi * self.radius * self.radius
                end
                
                function circle:getCircumference()
                    return 2 * math.pi * self.radius
                end
                
                return circle
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Access tables from Haxe
        var fruits = interp.resolve("fruits");
        var person = interp.resolve("person");
        var mixed = interp.resolve("mixed");
        
        // Work with array-like tables
        trace("Fruits:");
        for (i in 1...fruits.length + 1) {
            trace("  " + i + ": " + fruits[i]);
        }
        
        // Work with dictionary-like tables
        trace("Person:");
        trace("  Name: " + person.name);
        trace("  Age: " + person.age);
        trace("  City: " + person.city);
        
        // Work with mixed tables
        trace("Mixed table:");
        for (key in Reflect.fields(mixed)) {
            trace("  " + key + ": " + Reflect.field(mixed, key));
        }
        
        // Call a function that processes tables
        var processTable = interp.resolve("processTable");
        var processedFruits = processTable(fruits);
        trace("Processed fruits:");
        for (i in 1...processedFruits.length + 1) {
            trace("  " + i + ": " + processedFruits[i]);
        }
        
        // Work with tables that have methods
        var createCircle = interp.resolve("createCircle");
        var circle = createCircle(5);
        trace("Circle with radius " + circle.radius + ":");
        trace("  Area: " + circle.getArea());
        trace("  Circumference: " + circle.getCircumference());
    }
}
```

### Step 2: Update the Build File

Modify your `build.hxml` file to use this new class:

```hxml
-cp src
-main TablesExample
-neko output.n
--next
-cmd neko output.n
```

### Step 3: Run the Project

Execute the following command:

```bash
haxe build.hxml
```

You should see output similar to:

```
Fruits:
  1: apple
  2: banana
  3: orange
Person:
  Name: John
  Age: 30
  City: New York
Mixed table:
  1: first
  key: value
  2: second
  true: boolean value
Processed fruits:
  1: apple processed
  2: banana processed
  3: orange processed
Circle with radius 5:
  Area: 78.53981633974483
  Circumference: 31.41592653589793
```

### Explanation

1. We demonstrated different types of tables in Lua:
   - Array-like tables with numeric indices
   - Dictionary-like tables with string keys
   - Mixed tables with various key types
2. We showed how to access table elements from Haxe using both array and object notation.
3. We created a function that processes tables and returns a modified version.
4. We demonstrated how to create tables with methods (similar to objects in OOP).
5. We showed how to call methods on Lua tables from Haxe.

---

## 5. Control Structures

Let's explore how to use Lua's control structures in Luahscript.

### Step 1: Create a New Example

Create a file `src/ControlStructures.hx` with the following content:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class ControlStructures {
    public static function main() {
        // Define a Lua script with control structures
        var luaScript = '
            -- Function to demonstrate if-elseif-else
            function checkNumber(num)
                if num > 0 then
                    return "Positive"
                elseif num < 0 then
                    return "Negative"
                else
                    return "Zero"
                end
            end
            
            -- Function to demonstrate while loop
            function countDown(start)
                local result = {}
                local i = start
                while i > 0 do
                    table.insert(result, i)
                    i = i - 1
                end
                return result
            end
            
            -- Function to demonstrate repeat-until loop
            function countUp(start, limit)
                local result = {}
                local i = start
                repeat
                    table.insert(result, i)
                    i = i + 1
                until i > limit
                return result
            end
            
            -- Function to demonstrate numeric for loop
            function range(start, stop, step)
                local result = {}
                for i = start, stop, step do
                    table.insert(result, i)
                end
                return result
            end
            
            -- Function to demonstrate generic for loop with ipairs
            function processArray(arr)
                local result = {}
                for i, v in ipairs(arr) do
                    result[i] = v * 2
                end
                return result
            end
            
            -- Function to demonstrate generic for loop with pairs
            function processObject(obj)
                local result = {}
                for k, v in pairs(obj) do
                    result[k] = v .. " processed"
                end
                return result
            end
            
            -- Function with nested loops
            function multiplicationTable(size)
                local result = {}
                for i = 1, size do
                    result[i] = {}
                    for j = 1, size do
                        result[i][j] = i * j
                    end
                end
                return result
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Test if-elseif-else
        var checkNumber = interp.resolve("checkNumber");
        trace("checkNumber(5): " + checkNumber(5));
        trace("checkNumber(-3): " + checkNumber(-3));
        trace("checkNumber(0): " + checkNumber(0));
        
        // Test while loop
        var countDown = interp.resolve("countDown");
        var countdownResult = countDown(5);
        trace("Countdown from 5: " + countdownResult);
        
        // Test repeat-until loop
        var countUp = interp.resolve("countUp");
        var countupResult = countUp(1, 5);
        trace("Count up from 1 to 5: " + countupResult);
        
        // Test numeric for loop
        var range = interp.resolve("range");
        var rangeResult = range(1, 10, 2);
        trace("Range from 1 to 10 with step 2: " + rangeResult);
        
        // Test generic for loop with ipairs
        var processArray = interp.resolve("processArray");
        var arrayInput = [1, 2, 3, 4, 5];
        var arrayResult = processArray(arrayInput);
        trace("Array processing result: " + arrayResult);
        
        // Test generic for loop with pairs
        var processObject = interp.resolve("processObject");
        var objectInput = {a: "hello", b: "world", c: "lua"};
        var objectResult = processObject(objectInput);
        trace("Object processing result: " + objectResult);
        
        // Test nested loops
        var multiplicationTable = interp.resolve("multiplicationTable");
        var multTable = multiplicationTable(3);
        trace("Multiplication table (3x3):");
        for (i in 1...multTable.length + 1) {
            var row = "";
            for (j in 1...multTable[i].length + 1) {
                row += multTable[i][j] + " ";
            }
            trace(row);
        }
    }
}
```

### Step 2: Update the Build File

Modify your `build.hxml` file to use this new class:

```hxml
-cp src
-main ControlStructures
-neko output.n
--next
-cmd neko output.n
```

### Step 3: Run the Project

Execute the following command:

```bash
haxe build.hxml
```

You should see output similar to:

```
checkNumber(5): Positive
checkNumber(-3): Negative
checkNumber(0): Zero
Countdown from 5: 5,4,3,2,1
Count up from 1 to 5: 1,2,3,4,5
Range from 1 to 10 with step 2: 1,3,5,7,9
Array processing result: 2,4,6,8,10
Object processing result: [object Object]
Multiplication table (3x3):
1 2 3 
2 4 6 
3 6 9 
```

### Explanation

1. We demonstrated various control structures in Lua:
   - `if-elseif-else` statements for conditional execution
   - `while` loops for iteration with a condition
   - `repeat-until` loops for post-condition iteration
   - Numeric `for` loops for iterating with a start, stop, and step
   - Generic `for` loops with `ipairs` for array-like tables
   - Generic `for` loops with `pairs` for dictionary-like tables
   - Nested loops for more complex operations
2. We showed how to call these Lua functions from Haxe and process their results.
3. We demonstrated how to pass Haxe arrays and objects to Lua functions and receive results back.

---

## 6. Error Handling

Error handling is an important aspect of any programming language. Let's explore how to handle errors in Lua scripts with Luahscript.

### Step 1: Create a New Example

Create a file `src/ErrorHandling.hx` with the following content:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class ErrorHandling {
    public static function main() {
        // Define a Lua script with error handling
        var luaScript = '
            -- Function that may throw an error
            function divide(a, b)
                if b == 0 then
                    error("Division by zero!")
                end
                return a / b
            end
            
            -- Function with error handling using pcall
            function safeDivide(a, b)
                local status, result = pcall(function()
                    return divide(a, b)
                end)
                
                if status then
                    return { success = true, result = result }
                else
                    return { success = false, error = result }
                end
            end
            
            -- Function with custom error handling
            function parseNumber(str)
                local num = tonumber(str)
                if num == nil then
                    return nil, "Invalid number: " .. str
                end
                return num
            end
            
            -- Function with assert
            function checkValue(value)
                assert(value ~= nil, "Value cannot be nil")
                assert(type(value) == "number", "Value must be a number")
                return value * 2
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Get the Lua functions
        var divide = interp.resolve("divide");
        var safeDivide = interp.resolve("safeDivide");
        var parseNumber = interp.resolve("parseNumber");
        var checkValue = interp.resolve("checkValue");
        
        // Test error handling with try-catch in Haxe
        try {
            trace("10 / 2 = " + divide(10, 2));
            trace("10 / 0 = " + divide(10, 0));
        } catch (e:Dynamic) {
            trace("Caught error: " + e);
        }
        
        // Test pcall-based error handling
        var result1 = safeDivide(10, 2);
        if (result1.success) {
            trace("10 / 2 = " + result1.result);
        } else {
            trace("Error: " + result1.error);
        }
        
        var result2 = safeDivide(10, 0);
        if (result2.success) {
            trace("10 / 0 = " + result2.result);
        } else {
            trace("Error: " + result2.error);
        }
        
        // Test custom error handling
        var numResult = parseNumber("123");
        if (numResult != null) {
            trace("Parsed number: " + numResult);
        } else {
            trace("Failed to parse number");
        }
        
        var numResult2 = parseNumber("abc");
        if (numResult2 != null) {
            trace("Parsed number: " + numResult2);
        } else {
            trace("Failed to parse number");
        }
        
        // Test assert
        try {
            trace("checkValue(5): " + checkValue(5));
            trace("checkValue(nil): " + checkValue(nil));
        } catch (e:Dynamic) {
            trace("Caught error: " + e);
        }
        
        try {
            trace("checkValue(\"hello\"): " + checkValue("hello"));
        } catch (e:Dynamic) {
            trace("Caught error: " + e);
        }
    }
}
```

### Step 2: Update the Build File

Modify your `build.hxml` file to use this new class:

```hxml
-cp src
-main ErrorHandling
-neko output.n
--next
-cmd neko output.n
```

### Step 3: Run the Project

Execute the following command:

```bash
haxe build.hxml
```

You should see output similar to:

```
10 / 2 = 5
Caught error: Division by zero!
10 / 2 = 5
Error: Division by zero!
Parsed number: 123
Failed to parse number
checkValue(5): 10
Caught error: Value cannot be nil
Caught error: Value must be a number
```

### Explanation

1. We demonstrated different approaches to error handling in Lua:
   - Using the `error()` function to throw errors
   - Using `pcall()` (protected call) to catch errors in Lua
   - Returning multiple values to indicate success or failure
   - Using `assert()` to check conditions and throw errors if they fail
2. We showed how to handle Lua errors in Haxe using try-catch blocks.
3. We demonstrated how to process the results of Lua functions that use `pcall()` for error handling.
4. We showed how to work with Lua functions that return multiple values, including error information.

---

## 7. Advanced Features: Metatables

Metatables are a powerful feature in Lua that allows you to change the behavior of tables. Let's explore how to use them with Luahscript.

### Step 1: Create a New Example

Create a file `src/MetatablesExample.hx` with the following content:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class MetatablesExample {
    public static function main() {
        // Define a Lua script with metatables
        var luaScript = '
            -- Function to create a vector with metatable
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
                    __mul = function(a, b)
                        if type(a) == "number" then
                            return createVector(b.x * a, b.y * a)
                        elseif type(b) == "number" then
                            return createVector(a.x * b, a.y * b)
                        else
                            error("Invalid operands for vector multiplication")
                        end
                    end,
                    __div = function(a, b)
                        if type(b) == "number" then
                            return createVector(a.x / b, a.y / b)
                        else
                            error("Invalid operands for vector division")
                        end
                    end,
                    __unm = function(a)
                        return createVector(-a.x, -a.y)
                    end,
                    __eq = function(a, b)
                        return a.x == b.x and a.y == b.y
                    end,
                    __tostring = function(v)
                        return "(" .. v.x .. ", " .. v.y .. ")"
                    end,
                    __index = function(t, k)
                        if k == "length" then
                            return math.sqrt(t.x * t.x + t.y * t.y)
                        elseif k == "normalized" then
                            local len = t.length
                            if len == 0 then
                                return createVector(0, 0)
                            else
                                return createVector(t.x / len, t.y / len)
                            end
                        end
                    end
                })
                
                return vector
            end
            
            -- Function to demonstrate inheritance with metatables
            function createAnimal(name)
                local animal = { name = name }
                
                setmetatable(animal, {
                    __index = {
                        speak = function(self)
                            return self.name .. " makes a sound"
                        end
                    }
                })
                
                return animal
            end
            
            function createDog(name, breed)
                local dog = createAnimal(name)
                dog.breed = breed
                
                setmetatable(dog, {
                    __index = {
                        speak = function(self)
                            return self.name .. " (" .. self.breed .. ") barks"
                        end,
                        fetch = function(self)
                            return self.name .. " fetches the ball"
                        end
                    }
                })
                
                return dog
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Test vector operations
        var createVector = interp.resolve("createVector");
        var v1 = createVector(3, 4);
        var v2 = createVector(1, 2);
        
        trace("v1 = " + v1);
        trace("v2 = " + v2);
        trace("v1 + v2 = " + (v1 + v2));
        trace("v1 - v2 = " + (v1 - v2));
        trace("v1 * 2 = " + (v1 * 2));
        trace("v1 / 2 = " + (v1 / 2));
        trace("-v1 = " + (-v1));
        trace("v1 == v2: " + (v1 == v2));
        trace("v1 length: " + v1.length);
        trace("v1 normalized: " + v1.normalized);
        
        // Test inheritance
        var createAnimal = interp.resolve("createAnimal");
        var createDog = interp.resolve("createDog");
        
        var animal = createAnimal("Generic Animal");
        var dog = createDog("Rex", "Golden Retriever");
        
        trace("Animal speaks: " + animal.speak(animal));
        trace("Dog speaks: " + dog.speak(dog));
        trace("Dog fetches: " + dog.fetch(dog));
    }
}
```

### Step 2: Update the Build File

Modify your `build.hxml` file to use this new class:

```hxml
-cp src
-main MetatablesExample
-neko output.n
--next
-cmd neko output.n
```

### Step 3: Run the Project

Execute the following command:

```bash
haxe build.hxml
```

You should see output similar to:

```
v1 = (3, 4)
v2 = (1, 2)
v1 + v2 = (4, 6)
v1 - v2 = (2, 2)
v1 * 2 = (6, 8)
v1 / 2 = (1.5, 2)
-v1 = (-3, -4)
v1 == v2: false
v1 length: 5
v1 normalized: (0.6, 0.8)
Animal speaks: Generic Animal makes a sound
Dog speaks: Rex (Golden Retriever) barks
Dog fetches: Rex fetches the ball
```

### Explanation

1. We demonstrated how to use metatables to create custom behaviors for tables:
   - Arithmetic operations (`__add`, `__sub`, `__mul`, `__div`, `__unm`)
   - Comparison operations (`__eq`)
   - String conversion (`__tostring`)
   - Property access (`__index`)
2. We showed how to create a vector type with custom operations using metatables.
3. We demonstrated how to implement inheritance using metatables with the `__index` metamethod.
4. We showed how to access these custom behaviors from Haxe, including operator overloading and dynamic properties.

---

## 8. Integrating Lua with Haxe

In this final example, we'll demonstrate how to integrate Lua scripting more deeply with your Haxe application, including passing Haxe objects to Lua and calling Haxe functions from Lua.

### Step 1: Create a New Example

Create a file `src/IntegrationExample.hx` with the following content:

```haxe
package;

import luahscript.LuaParser;
import luahscript.LuaInterp;
import luahscript.exprs.LuaExpr;

class IntegrationExample {
    public static function main() {
        // Create a Haxe object to expose to Lua
        var haxeObject = {
            name: "Haxe Object",
            value: 42,
            method: function() {
                return "Called from Haxe!";
            },
            calculate: function(a:Float, b:Float) {
                return a * b;
            }
        };
        
        // Define a Lua script that interacts with Haxe
        var luaScript = '
            -- Function to work with Haxe objects
            function processHaxeObject(obj)
                print("Object name: " .. obj.name)
                print("Object value: " .. obj.value)
                print("Method result: " .. obj:method())
                print("Calculation result: " .. obj:calculate(5, 3))
                
                -- Modify the object
                obj.value = obj.value * 2
                
                return "Object processed"
            end
            
            -- Function that creates a Lua object to be used in Haxe
            function createLuaObject(name, values)
                local obj = {
                    name = name,
                    values = values,
                    sum = function(self)
                        local total = 0
                        for i, v in ipairs(self.values) do
                            total = total + v
                        end
                        return total
                    end,
                    average = function(self)
                        if #self.values == 0 then
                            return 0
                        end
                        return self:sum() / #self.values
                    end
                }
                
                return obj
            end
            
            -- Function that demonstrates callbacks
            function withCallback(data, callback)
                local results = {}
                for i, v in ipairs(data) do
                    results[i] = callback(v)
                end
                return results
            end
        ';
        
        // Parse and execute the script
        var parser = new LuaParser();
        var expr = parser.parseFromString(luaScript);
        var interp = new LuaInterp();
        interp.execute(expr);
        
        // Get the Lua functions
        var processHaxeObject = interp.resolve("processHaxeObject");
        var createLuaObject = interp.resolve("createLuaObject");
        var withCallback = interp.resolve("withCallback");
        
        // Pass Haxe object to Lua
        trace("Original Haxe object value: " + haxeObject.value);
        var processResult = processHaxeObject(haxeObject);
        trace("Process result: " + processResult);
        trace("Modified Haxe object value: " + haxeObject.value);
        
        // Get Lua object and use it in Haxe
        var luaObject = createLuaObject("Lua Object", [1, 2, 3, 4, 5]);
        trace("Lua object name: " + luaObject.name);
        trace("Lua object sum: " + luaObject.sum(luaObject));
        trace("Lua object average: " + luaObject.average(luaObject));
        
        // Use callback function
        var data = [1, 2, 3, 4, 5];
        var callbackResult = withCallback(data, function(x) {
            return x * 2;
        });
        trace("Callback result: " + callbackResult);
        
        // Expose a Haxe function to Lua
        interp.globals.set("haxeFunction", function(x:Int, y:Int) {
            return x + y;
        });
        
        // Define a Lua script that uses the Haxe function
        var luaScript2 = '
            function useHaxeFunction(a, b)
                return haxeFunction(a, b)
            end
        ';
        
        // Parse and execute the second script
        var expr2 = parser.parseFromString(luaScript2);
        interp.execute(expr2);
        
        // Get the function and call it
        var useHaxeFunction = interp.resolve("useHaxeFunction");
        var haxeFunctionResult = useHaxeFunction(10, 20);
        trace("Haxe function result: " + haxeFunctionResult);
    }
}
```

### Step 2: Update the Build File

Modify your `build.hxml` file to use this new class:

```hxml
-cp src
-main IntegrationExample
-neko output.n
--next
-cmd neko output.n
```

### Step 3: Run the Project

Execute the following command:

```bash
haxe build.hxml
```

You should see output similar to:

```
Original Haxe object value: 42
Object name: Haxe Object
Object value: 42
Method result: Called from Haxe!
Calculation result: 15
Process result: Object processed
Modified Haxe object value: 84
Lua object name: Lua Object
Lua object sum: 15
Lua object average: 3
Callback result: 2,4,6,8,10
Haxe function result: 30
```

### Explanation

1. We demonstrated how to pass Haxe objects to Lua scripts and access their properties and methods.
2. We showed how Lua scripts can modify Haxe objects, with the changes reflected back in Haxe.
3. We created Lua objects with methods and used them in Haxe.
4. We demonstrated how to pass Haxe functions as callbacks to Lua scripts.
5. We showed how to expose Haxe functions to the Lua environment using the `globals` map.
6. We demonstrated how Lua scripts can call these exposed Haxe functions.

---

## Conclusion

Congratulations! You've completed the Luahscript tutorial. You now have a solid understanding of how to:

- Set up a project with Luahscript
- Parse and execute Lua scripts from Haxe
- Work with Lua variables, functions, and tables
- Use Lua control structures
- Handle errors in Lua scripts
- Utilize advanced features like metatables
- Integrate Lua scripting deeply with your Haxe applications

With this knowledge, you can now leverage the power and flexibility of Lua scripting in your Haxe projects. Whether you're creating game mods, plugin systems, or just want to add scripting capabilities to your application, Luahscript provides a robust solution.

## Next Steps

To continue your journey with Luahscript, consider:

- Exploring more advanced Lua features
- Creating a real-world project that uses Luahscript
- Contributing to the Luahscript project
- Experimenting with performance optimizations
- Exploring integration with other Haxe libraries

Happy coding!