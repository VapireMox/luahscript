-- 定义模块表
local mymath = {}

-- 私有变量（模块内可见）
local PI = 3.14159

-- 公开函数：加法
function mymath.add(a, b)
    return a + b
end

-- 公开函数：减法
function mymath.sub(a, b)
    return a - b
end

-- 公开函数：乘法
function mymath.mul(a, b)
    return a * b
end

-- 公开函数：除法（带错误检查）
function mymath.div(a, b)
    if b == 0 then
        error("Division by zero!")
    end
    return a / b
end

-- 公开函数：计算圆面积
function mymath.circle_area(radius)
    return PI * radius * radius
end

-- 返回模块表
return mymath
