---
--- 游戏服
--- 处理游戏逻辑
---
local skynet = require "skynet"
local const = require "const"

local service = {
}

local name = ...
skynet.start(function ()
    service.name = name

    -- 注册服务rpc函数
    skynet.dispatch("lua", function (session, address, cmd, ...)
        local fun = service[cmd];
        if fun then
            local ret = fun(service, ...);
            local data, size = skynet.pack(ret);
            skynet.ret(data, size)
        else
            error(string.format("error service_game.%s.start: unknown command %s", name, cmd))
        end
    end)

    -- 向中心服注册自己
    service.center = skynet.queryservice("service_center/service")
    skynet.call(service.center, 'lua', 'register_service', const.service_type.GAME, name, skynet.self())
end)