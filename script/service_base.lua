---
--- 服务基类
---

local skynet = require "skynet"
local oo = require "utils.oo"
local const = require "const"

local ServiceBase = oo.class('ServiceBase')

function ServiceBase._init(self, type, name)
    -- 服务类型 const.service_type
    self.type = type
    -- 服务名字
    self.name = name
    -- 中心服地址
    self.center = nil
    -- 服务列表: {type: {name: {type:, name, addr:}}}
    -- 中心服会接收其他服注册信息，等各个服务启动完成之后，会将此数据同步给其他服务
    self.service_map = {}
end

-- 中心服方法，同步service给其他服务
function ServiceBase._sync_service_map(self)
    for _, services in pairs(self.service_map) do
        for _, svc in pairs(services) do
            skynet.call(svc.addr, "lua", "on_sync_service_map", self.service_map)
        end
    end
end

-- 非中心服方法，接收中心服同步的service_map
function ServiceBase.on_sync_service_map(self, service_map)
    self.service_map = service_map;
end

-- 非中心服方法，向中心服注册
function ServiceBase.register_to_center(self)
    self.center = skynet.queryservice("service_center/service")
    skynet.call(self.center, 'lua', 'register_service', self.type, self.name, skynet.self())
end

-- 获取某个服务的地址
function ServiceBase.get_service_addr(self, type, name)
    local services = self.service_map[type]
    if services then
        local conf = services[name]
        if conf then
            return conf.addr
        end
    end
end

-- 注册服务间回调
function ServiceBase.register_rpc(self)
    skynet.dispatch("lua", function (session, address, cmd, ...)
       local fun = self[cmd];
        if fun then
            local ret = fun(self, ...);
            local data, size = skynet.pack(ret);
            skynet.ret(data, size)
        else
            error(string.format("error %s.start: unknown command %s", self.name, cmd))
        end
    end)
end

-- 启动回调
function ServiceBase.on_start(self)
    self:register_rpc();
    if self.type ~= const.service_type.CENTER then
        self:register_to_center()
    end
end

-- 启动服务
function ServiceBase.start(self)
    skynet.start(function ()
        self:on_start()
    end);
end

return ServiceBase