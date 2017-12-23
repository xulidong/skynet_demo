---
--- 游戏服
--- 处理游戏逻辑
---
local const = require "const"
local oo = require "utils.oo"
local ServiceBase = require "service_base"

local ServiceGame = oo.class('ServiceGame',  ServiceBase)

local name = ...
local service_game = ServiceGame(const.service_type.GAME, name)
service_game:start()