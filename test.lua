-- Lua 语法测试脚本
-- 本脚本测试 Lua 的各种语法特性
--[[
	- 由傻逼且脑瘫dickseek生成
]]

print("=== Lua 语法测试开始 ===\n")

-- 1. 变量和基本数据类型
print("1. 变量和基本数据类型")
local num = 42          -- 数字
local str = "Hello"     -- 字符串
local bool = true       -- 布尔值
local nilVar = nil      -- nil
local func = function() return "function" end  -- 函数

print("数字:", num)
print("字符串:", str)
print("布尔值:", bool)
print("nil:", nilVar)
print("函数调用:", func())
print()

-- 2. 表（Table） - Lua的核心数据结构
print("2. 表（Table）")
local table1 = {1, 2, 3, 4}  -- 数组式表
local table2 = {              -- 字典式表
    name = "Lua",
    version = "5.4",
    isCool = true
}

-- 遍历数组表
print("数组表:")
for i, v in ipairs(table1) do
    print(i, v)
end

-- 遍历字典表
print("字典表:")
for k, v in pairs(table2) do
    print(k, v)
end
print()

-- 3. 控制结构
print("3. 控制结构")

-- if 语句
local x = 5
if x > 5 then
    print("x 大于 5")
elseif x == 5 then
    print("x 等于 5")
else
    print("x 小于 5")
end

-- while 循环
print("while 循环:")
local i = 1
while i <= 3 do
    print("循环次数:", i)
    i = i + 1
end

-- repeat until 循环
print("repeat until 循环:")
local j = 1
repeat
    print("循环次数:", j)
    j = j + 1
until j > 3

-- for 循环
print("for 循环:")
for k = 1, 5, 2 do  -- 从1到5，步长为2
    print("k =", k)
end
print()

-- 4. 函数
print("4. 函数")

-- 基本函数
function add(a, b)
    return a + b
end

-- 可变参数函数
function sum(...)
    local result = 0
    local args = {...}
    for _, v in ipairs(args) do
        result = result + v
    end
    return result
end

-- 匿名函数
local multiply = function(a, b) return a * b end

print("add(5, 3) =", add(5, 3))
print("sum(1, 2, 3, 4) =", sum(1, 2, 3, 4))
print("multiply(4, 5) =", multiply(4, 5))
print()

-- 5. 元表（Metatable）和元方法（Metamethod）
print("5. 元表和元方法")

local t1 = {value = 10}
local t2 = {value = 20}

-- 创建元表
local mt = {
    __add = function(a, b)
        return {value = a.value + b.value}
    end,
    __tostring = function(t)
        return "value: " .. t.value
    end
}

setmetatable(t1, mt)
setmetatable(t2, mt)

local t3 = t1 + t2
local abab = "{"
for k,v in pairs(t3) do
	abab = abab..k.."="..v
end
abab = abab.."}"
print("t1 + t2 =", abab)
print()

-- 6. 协程（Coroutine）
print("6. 协程（未完成）")

--[[local co = coroutine.create(function()
    for i = 1, 3 do
        print("协程执行:", i)
        coroutine.yield()
    end
end)

print("协程状态:", coroutine.status(co))
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
print("协程状态:", coroutine.status(co))
print()]]

-- 7. 错误处理
print("7. 错误处理")

local success, result = pcall(function()
    error("这是一个测试错误!")
end)
if not success then
    print("捕获到错误:", result)
end

-- 8. 模块系统
print("8. 模块系统")

-- 模拟一个模块
local mymodule = {}
function mymodule.greet(name)
    return "Hello, " .. (name or "World")
end

print(mymodule.greet("Lua"))
print()

-- 9. 高级特性: 闭包
print("9. 闭包")

function createCounter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end

local counter = createCounter()
print("计数器:", counter())
print("计数器:", counter())
print("计数器:", counter())
print()

-- 10. 字符串操作
print("10. 字符串操作")
local s = "Lua Programming"
print("字符串长度:", #s)
print("大写:", string.upper(s))
print("小写:", string.lower(s))
print("子字符串:", string.sub(s, 5, 7))
print("查找 'Pro':", string.find(s, "Pro"))
print()

-- 11. 数学运算
print("11. 数学运算")
print("绝对值:", math.abs(-10))
print("平方根:", math.sqrt(16))
print("随机数:", math.random())
print("π的值:", math.pi)
print()


-- 12. 表操作
print("12. 表操作（未完成）")
--[[local t = {3, 1, 4, 2}
table.insert(t, 5)
print("插入后:")
for i, v in ipairs(t) do print(i, v) end

table.sort(t)
print("排序后:")
for i, v in ipairs(t) do print(i, v) end

table.remove(t, 1)
print("删除第一个元素后:")
for i, v in ipairs(t) do print(i, v) end
print()]]

print("=== Lua 语法测试完成 ===")