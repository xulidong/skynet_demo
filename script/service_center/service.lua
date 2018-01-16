---
--- 中心服
--- 记录所有服务地址
---

local skynet = require "skynet"
local oo = require "utils.oo"
local const = require "const"
local ServiceBase = require "service_base"

local ServiceCenter = oo.class('ServiceCenter',  ServiceBase)

function ServiceCenter._init(self, type, name)
    ServiceBase._init(self, type, name)

    self.account_dict = {}			  -- 帐号列表
    self.account_count = 0			  -- 账号数量
end

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
        error(string.format("error service_center.register_service: service %s is already exist", name))
    end
end

--- 所有服都启动完成后，回调用这个方法
function ServiceCenter.all_service_start_done(self)
    self:_sync_service_map()
    self:_notify_start_done()
    self.starting = false
end

--- 同步service给其他服务
function ServiceCenter._sync_service_map(self)
    for type, services in pairs(self.service_map) do
        if type ~= const.service_type.CENTER then
            for name, service in pairs(services) do
                skynet.call(service.addr, 'lua', 'on_sync_service_map', self.service_map)
            end
        end
    end
end

--- 通知其他服启动完成
function ServiceCenter._notify_start_done(self)
    for type, services in pairs(self.service_map) do
        for name, service in pairs(services) do
            skynet.call(service.addr, 'lua', 'on_notify_start_done', self.service_map)
        end
    end
end


---帐号通知：账号登陆
--@param gate_addr gate地址
--@param acckey 账号ID
--@param uid 帐号类唯一ID
--@param ip 登陆IP
--@return const.account_status
function ServiceCenter.account_login(self, gate_addr, acckey)
    local account = self.account_dict[acckey]
    local now = skynet.time()
    if account then
        if account.status == const.account_status.LOGINING then
            return const.account_status.LOGINING
        elseif account.status == const.account_status.LOGINED then
            account.status = const.account_status.KICKING
            account.change_time = now
            skynet.send(account.gate_addr, 'lua', 'kick_account', acckey)
            return const.account_status.KICKING
        elseif account.status == const.account_status.KICKING then
            return const.account_status.KICKING
        else
            return const.account_status.UNKNOWN
        end
    else
        self.account_dict[acckey] = {
            gate_addr = gate_addr,
            status = const.account_status.LOGINING,
            change_time = now,
        }
        self.account_count = self.account_count + 1
        return const.account_status.UNLOGIN
    end
end

---帐号通知：登陆完成了
--@param acckey 账号ID
function ServiceCenter.account_logined(self, acckey)
    local account = self.account_dict[acckey]
    account.status = const.account_status.LOGINED
    account.change_time = skynet.time()
end

---帐号登出
--@param acckey 账号ID
function ServiceCenter.account_logout(self, acckey, uid, status)
    self.account_dict[acckey] = nil
    self.account_count = self.account_count -1
end

local name = ...
local service_center = ServiceCenter(const.service_type.CENTER, name);
service_center:start();