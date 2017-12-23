---
--- 网关服
--- 负责与前端交互和消息的转发
---

local socket = require "skynet.socket"
local cjson = require "cjson"
local const = require "const"
local service_conf = require "service_conf"
local Account = require "service_gate.account"
local oo = require "utils.oo"
local ServiceBase = require "service_base"

local ServiceGate = oo.class('ServiceGate',  ServiceBase)

function ServiceGate._init(self, type, name)
    ServiceBase._init(self, type, name)

    self.client_addr = {} -- {id: addr}
    self.db = nil -- 数据库
end


function ServiceGate.on_connect (self, id, addr)
    self.client_addr[id] = Account(id, addr);
end

function ServiceGate.on_disconnect (self, id, addr)
    self.client_addr[id] = nil;
end

function ServiceGate.on_data (self, id, addr)
    local acc = self.client_addr[id];
    if not acc then
        error("error service_gate.data: data from unknow account addr: " .. addr .. " id: " .. id)
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
                error("error cjson.decode msg "..msg.." error "..ret)
            end
        else
            service.on_disconnect (id, addr)
            socket.close(id)
        end
    end
end

function ServiceGate.accept(self, id, addr)
    if not self.client_addr[id] then
        self:on_connect(id, addr)
    end
    self:on_data(id, addr)
end


function ServiceGate.on_start(self)
    ServiceBase.on_start(self)

    -- 读取配置
    local gate_list = service_conf.gate_list
    local conf = gate_list[self.name]

    -- 数据库
    assert(conf.db ~= nil)
    self.db = self:get_service_addr(const.service_type.DB, conf.db)

    -- 监听 socket 连接
    local listen_id = assert(socket.listen(conf.host, conf.port))
    socket.start(listen_id , function(id, addr)
        self:accept(id, addr);
    end)
end

local name = ...
local service_gate = ServiceGate(const.service_type.GATE, name)
service_gate:start()