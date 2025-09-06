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
print("12. 表操作")

-- table.insert 测试
local t1 = {3, 1, 4, 2}
print("原始表:")
for i, v in ipairs(t1) do print(i, v) end

table.insert(t1, 5)
print("在末尾插入5后:")
for i, v in ipairs(t1) do print(i, v) end

table.insert(t1, 2, 99)
print("在位置2插入99后:")
for i, v in ipairs(t1) do print(i, v) end

-- table.remove 测试
table.remove(t1, 1)
print("删除第一个元素后:")
for i, v in ipairs(t1) do print(i, v) end

local removed = table.remove(t1)
print("删除末尾元素:", removed)
print("删除末尾后:")
for i, v in ipairs(t1) do print(i, v) end

-- table.sort 测试
local t2 = {5, 2, 8, 1, 3}
print("排序前:")
for i, v in ipairs(t2) do print(i, v) end

table.sort(t2)
print("升序排序后:")
for i, v in ipairs(t2) do print(i, v) end

-- 自定义排序
table.sort(t2, function(a, b) return a > b end)
print("降序排序后:")
for i, v in ipairs(t2) do print(i, v) end

-- table.concat 测试
local t3 = {"Hello", "World", "Lua"}
print("连接字符串:", table.concat(t3))
print("用空格连接:", table.concat(t3, " "))
print("用逗号连接:", table.concat(t3, ", "))

-- table.maxn 测试 (如果可用)
local t4 = {10, 20, 30, [5] = 50}
print("表长度:", #t4)
if table.maxn then
    print("最大索引:", table.maxn(t4))
end

-- table.unpack 测试
local t5 = {"a", "b", "c"}
local a, b, c = table.unpack(t5)
print("解包结果:", a, b, c)

-- table.move 测试 (如果可用)
if table.move then
    local t6 = {1, 2, 3, 4, 5}
    table.move(t6, 1, 3, 5)
    print("table.move后:")
    for i, v in ipairs(t6) do print(i, v) end
end

print()

-- 13. 高级表操作
print("13. 高级表操作")

-- 表作为字典使用
local dict = {
    apple = "苹果",
    banana = "香蕉", 
    orange = "橙子"
}

print("字典遍历:")
for k, v in pairs(dict) do
    print(k, "=", v)
end

-- 表的长度操作
local arr = {10, 20, 30, nil, 50}
print("数组长度:", #arr)

-- 表的复制
function tableCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

local original = {a = 1, b = 2}
local copy = tableCopy(original)
copy.c = 3
print("原始表a:", original.a)
print("复制表c:", copy.c)

-- 表的合并
function tableMerge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do result[k] = v end
    for k, v in pairs(t2) do result[k] = v end
    return result
end

local merged = tableMerge({x = 1}, {y = 2, z = 3})
print("合并后的表:")
for k, v in pairs(merged) do print(k, v) end

print("=== Lua 语法测试完成 ===")