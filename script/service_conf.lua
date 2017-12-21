---
--- 服务配置
---

local conf = {}

conf.server_id = 1
conf.server_name =  "开发服"

conf.db_list = {
    db1 = {
        id = 1,
        host =  "127.0.0.1",
        port = 5001
    },
    db2 = {
        id = 2,
        host =  "127.0.0.1",
        port = 5001
    },
    db3 = {
        id = 3,
        host =  "127.0.0.1",
        port = 5001
    },
    db4 = {
        id = 4,
        host =  "127.0.0.1",
        port = 5001
    },
}

conf.game_list = {
    game1 = {
        id = 1,
    },
    game2 = {
        id = 2,
    },
    game3 = {
        id = 3,
    },
    game4 = {
        id = 4,
    },
}

conf.gate_list = {
    gate1 = {
        id = 1,
        host =  "0.0.0.0",
        port = 8101,
    },
    gate2 = {
        id = 2,
        host =  "0.0.0.0",
        port = 8102,
    }
}

return conf;