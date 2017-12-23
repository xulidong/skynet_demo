---
--- 客户端链接对象
---
local socket = require "skynet.socket"
local cjson = require "cjson"
local oo = require "utils.oo"
local cs = require "proto.cs"
local sc = require "proto.sc"

local Account = oo.class("Account")

function Account._init(self, id, addr)
    self.id = id;-- socke的id
    self.addr = addr; -- 客户端地址
    self.username = nil; -- 账号名字
end

function Account.on_message(self, args)
    local mid = args[1]

    if self[mid] then
        xpcall(self[mid], debug.traceback, self, table.unpack(args))
    else
        error ("error account.on_message: unknown msg id: "..mid)
    end
end

Account[cs.LOGIN] = function(self, mid, username)
    self.username = username;

    socket.write(self.id, cjson.encode({sc.LOGIN_RES, true}))
end

return Account