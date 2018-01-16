---
--- 客户端链接对象
---
local skynet = require "skynet"
local cjson = require "cjson"
local const = require "const"
local oo = require "utils.oo"
local cs = require "proto.cs"
local sc = require "proto.sc"
local service_conf = require "service_conf"

local Account = oo.class("Account")

function Account._init(self, ws, gate)
    self.ws = ws; -- 客户端的websocket
    self.gate = gate; -- 账号所在gate
    self.username = ""; -- 角色名字
    self.acckey = ""; -- 账号名字[服务器id+角色名字]
    self.status = const.account_status.UNLOGIN -- 当前状态 const.account_status
end


--- 从DB加载帐号
function Account._load_from_db(self)
	local now = math.floor(skynet.time())
	local ok, doc = skynet.call(self.gate.db, "lua", "db_findAndModify", const.dbcol.ACCOUNT, {
		query = { _id = self.acckey },
		update = {
			["$setOnInsert"] = { _id = self.acckey, ct = now},
			["$set"] = { llt = now, llp = self.ip },
		}
	})
	if ok then
        --- TODO
	else
		error("_load_from_db: failed, %s", self.acckey)
	end
end

--- 将角色简要信息发送给客户端
function Account._send_actor_summary(self)
    --- TODO
end

--- 处理登陆逻辑
function Account._do_login(self, acckey)
    self.acckey = acckey;
    self.status = const.account_status.LOGINING
    local ret = skynet.call(self.gate.center, 'lua', 'account_login', skynet.self(), self.acckey)
    if ret == const.account_status.UNLOGIN then
        self:_load_from_db()
        self.gate:on_account_logined(self)
        self.ws:send_text(cjson.encode({sc.LOGIN_RES, 0}))
        skynet.call(self.gate.center, 'lua', 'account_logined', self.acckey)
        self.status = const.account_status.LOGINED
        self:_send_actor_summary()
    elseif ret == const.account_status.LOGINING then
    elseif ret == const.account_status.LOGINED then
    elseif ret == const.account_status.KICKING then
    elseif ret == const.account_status.DESTROY then
    else
        error('Account._do_login: unknown state: %s , account: %s', ret, acckey)
    end
end

Account.on_kicked = function(self)
    --- TODO
end

Account[cs.LOGIN] = function(self, mid, username)
    self.username = username;
    local acckey = service_conf.server_id .. username;
    if self.status == const.account_status.UNLOGIN then
        self:_do_login(acckey)
    else
        self.ws:send_text(cjson.encode({sc.LOGIN_RES, 1}))
	end
end

function Account.on_message(self, args)
    local mid = args[1]
    local fun = self[mid]
    if fun then
        xpcall(fun, debug.traceback, self, table.unpack(args))
    else
        error("error account.on_message: unknown msg id: "..mid)
    end
end

return Account