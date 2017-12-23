---
--- 中心服
--- 记录所有服务地址
---

local oo = require "utils.oo"
local const = require "const"
local ServiceBase = require "service_base"

local ServiceCenter = oo.class('ServiceCenter',  ServiceBase)

function ServiceCenter.register_service(self, type, name, addr)
    local services = self.service_map[type]
    if not services then
        services = {}
        self.service_map[type] = services
    end
    if not services[name] then
        services[name] = {
            type = type,
            name = name,
            addr = addr,
        }
    else
        error(string.format("error service_center.register_service: service %s is always exist", name))
    end
end

function ServiceCenter.all_service_start_done(self)
    self:_sync_service_map()
end

local service_center = ServiceCenter(const.service_type.CENTER, name);
service_center:start();