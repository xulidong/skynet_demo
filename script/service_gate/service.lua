---
--- 网关服
--- 负责与前端交互和消息的转发
---

local skynet = require "skynet"
local socket = require "skynet.socket"
local cjson = require "cjson"
local const = require "const"
local service_conf = require "service_conf"
local Account = require "service_gate.account"

local name = ...

local service = {
    client_addr = {}, -- {id: addr}
    name = nil, -- 网关名
}

function service.conn (self, id, addr)
    print("connect from addr: " .. addr .. " id: " .. id)
    self.client_addr[id] = Account(id, addr);
end

function service.disconn (self, id, addr)

    self.client_addr[id] = nil;
end

function service.data (self, id, addr)
    local acc = self.client_addr[id];
    if not acc then
        print("data from unknow account addr: " .. addr .. " id: " .. id)
        return;
    end
    socket.start(id)
    while true do
        local msg = tostring(socket.read(id))
        if msg then
            local status, ret = xpcall(cjson.decode, debug.traceback, msg)
            if status then
                xpcall(acc.on_message, debug.traceback, acc, ret)
            else
                print("error cjson.decode msg "..msg.." error "..ret)
            end
        else
            service.disconn (id, addr)
            socket.close(id)
        end
    end
end

function service.accept(id, addr)
    if not service.client_addr[id] then
        service:conn(id, addr)
    end
    service:data(id, addr)
end

skynet.start(function()
    service.name = name

    -- 监听 socket 连接
    local gate_list = service_conf.gate_list
    print (name)
    local conf = gate_list[name]
    print(name, conf, conf.host, conf.port)
    local listen_id = assert(socket.listen(conf.host, conf.port))
    socket.start(listen_id , service.accept)

    -- 注册服务rpc函数
    skynet.dispatch("lua", function (session, address, cmd, ...)
        local fun = service[cmd];
        if fun then
            local ret = fun(service, ...);
            local data, size = skynet.pack(ret);
            skynet.ret(data, size)
        else
            error(string.format("error service_gate.%s.start: unknown command %s", name, cmd))
        end
    end)

    -- 向中心服注册自己
    service.center = skynet.queryservice("service_center/service")
    skynet.call(service.center, 'lua', 'register_service', const.service_type.GATE, name, skynet.self())
end)
