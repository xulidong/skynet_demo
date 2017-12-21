---
--- 中心服
--- 记录所有服务地址
---

local skynet = require "skynet"

local service = {
    service_dict = {},-- 服务列表: {type: {name: {type:, name, addr:}}}
}

function service.register_service(self, type, name, addr)
    local services = self.service_dict[type]
    if not services then
		services = {}
		self.service_dict[type] = services
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

skynet.start(function ()
    -- 注册服务rpc函数
    skynet.dispatch("lua", function (session, address, cmd, ...)
        local fun = service[cmd];
        if fun then
            local ret = fun(service, ...);
            local data, size = skynet.pack(ret);
            skynet.ret(data, size)
        else
            error(string.format("error service_center.start: unknown command %s", cmd))
        end
    end)
end)