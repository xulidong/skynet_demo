---
--- 模拟类
---

local oo = {}
oo._class_metatable = nil

function oo.class(classname, super)
    local newclass = {}
    newclass._classname = classname
    newclass._class = newclass
    newclass._super = super
    newclass._type = 'class'
    newclass.__index = newclass

    -- 把类的元表保存到全局变量
    local _class_metatable = oo._class_metatable
    if not _class_metatable then
        _class_metatable = {
            __index = function (t, k)
                local sup = rawget(t, '_super')
                if sup then
                    return sup[k]
                else
                    return nil
                end
            end,

            __call = function (cls, ...)
                local obj = {}
                obj._type = 'object'
                setmetatable(obj, cls)
                local _init = cls._init
                if _init then
                    _init(obj, ...)
                end
                return obj
            end
        }
        oo._class_metatable = _class_metatable
    end
    setmetatable(newclass, _class_metatable)
    return newclass
end

return oo