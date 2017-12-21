---
--- 脚本入口
---

local skynet = require "skynet"
local service_conf = require "service_conf"

skynet.start(function()
    -- 中心服
    skynet.uniqueservice("service_center/service")

    -- 数据库服
    local db_list = service_conf.db_list
    for db, _ in pairs(db_list) do
        skynet.newservice("service_db/service", db)
    end

    -- 游戏服
    local game_list = service_conf.game_list
    for game, _ in pairs(game_list) do
        skynet.newservice("service_game/service", game)
    end

    -- 网关服
    local gate_list = service_conf.gate_list
    for gate, _ in pairs(gate_list) do
        skynet.newservice("service_gate/service", gate)
    end

    skynet.exit()
end)
