---
--- 网关服
--- 负责与前端交互和消息的转发
---

local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local cjson = require "cjson"
local websocket = require "websocket"
local const = require "const"
local service_conf = require "service_conf"
local Account = require "service_gate.account"
local oo = require "utils.oo"
local ServiceBase = require "service_base"

local handler = {}
local ServiceGate = oo.class('ServiceGate',  ServiceBase)

function ServiceGate._init(self, type, name)
    ServiceBase._init(self, type, name)
    self.client_addr = {} -- {id: ws}
    self.key_accounts = {} -- {acckey: account}
    self.db = nil -- 数据库
    self.conf = nil -- service_conf中的服务配置
end

function ServiceGate.on_sync_service_map(self, service_map)
    ServiceBase.on_sync_service_map(self, service_map)

    -- 数据库
    assert(self.conf.db ~= nil)
    self.db = self:get_service_addr(const.service_type.DB, self.conf.db)
end

function ServiceGate.on_start(self)
    ServiceBase.on_start(self)

    -- 读取配置
    local gate_list = service_conf.gate_list
    self.conf = gate_list[self.name]

    -- 监听 socket 连接
    local listen_id = assert(socket.listen(self.conf.host, self.conf.port))
    socket.start(listen_id , function(id, addr)
        socket.start(id)
        pcall(self.accept, self, id)
    end)
end

function ServiceGate.accept(self, id)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), nil)
    if code then
        if header.upgrade == "websocket" then
            local ws = websocket.new(id, header, handler)
            ws:start()
        end
    end
end

---center请求：踢掉帐号
--@param acckey 帐号key
function ServiceGate.kick_account(self, acckey)
	local account = self.key_accounts[acckey]
	account:on_kicked()
end

---帐号登陆成功
--@param account 帐号类
function ServiceGate.on_account_logined(self, account)
	if self.key_accounts[account.acckey] then
		error("on_account_login, account is always logined: %s", account.acckey)
	end
	self.key_accounts[account.acckey] = account
end

local name = ...
local service_gate = ServiceGate(const.service_type.GATE, name)
service_gate:start()

function handler.on_open(ws)
    local acc = service_gate.client_addr[ws.id]
    if acc then
        error("error service_gate: already exists account:" ..ws.id)
        return;
    end
    service_gate.client_addr[ws.id] = Account(ws, service_gate)
end

function handler.on_message(ws, msg)
    local acc = service_gate.client_addr[ws.id]
    if not acc then
        error("error service_gate: data from unknown account: " ..ws.id)
        return;
    end

    local args = cjson.decode(msg)
    acc.on_message(acc, args)
end

function handler.on_close(ws, code, reason)
    print ("on_close")
    service_gate.client_addr[ws.id] = nil
end