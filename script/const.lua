---
--- 常量定义
---

local const = {}

-- 服务器类型
const.service_type = {
    CENTER = 1, -- 中心服
    GATE = 2, -- 网关服
    DB = 3, -- 数据库服
    GAME = 4, -- 游戏服
}

-- 当前帐号状态
const.account_status = {
    UNLOGIN = 1, -- 未登陆
    LOGINING = 2, -- 正在登陆
    LOGINED = 3, -- 已经登陆完毕
    KICKING = 5, -- 正在被踢
    DESTROY = 9, -- 消毁
    UNKNOWN = 10000, -- 未知状态
}

-- DB集合名
const.dbcol = {
	ACCOUNT = 'account',		-- 帐号
	ACTOR = 'actor',			-- 角色
}

return const