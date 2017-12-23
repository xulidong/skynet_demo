---
--- 数据库服
--- 负责数据库的增删改查
---

local mongo = require "skynet.db.mongo"
local const = require "const"
local service_conf = require "service_conf"
local oo = require "utils.oo"
local ServiceBase = require "service_base"

local ServiceDb = oo.class('ServiceDb',  ServiceBase)

function ServiceDb._init(self, type, name)
    ServiceBase._init(self, type, name)

    self.db = nil -- mongodbname = nil, -- 数据库
end

---插入文档
--@param colname string 集合名
--@param doc table 文档语句
--@return boolean 是否成功
function ServiceDb.db_insert(self, colname, doc, isptr)
    local ret = self.db[colname]:safe_insert(doc)
    return ret and ret.n == 1
end

--- 批量插入文档
--@param colname string 集合名
--@param docs table 文档列表
--@return boolean 是否成功
function ServiceDb.db_batch_insert(self, colname, docs, isptr)
    self.db[colname]:batch_insert(docs)
    return true
end

--- 删除文档
-- @param colname string 集合名
-- @param query table 查询语句
-- @param single 是否只移除一个文档
-- @return boolean 是否成功
function ServiceDb.db_delete(self, colname, query, single)
    local col = self.db[colname]
    col:delete(query, single)
    return true
end

--- 查找并替换
-- @param colname string 集合名
-- @param doc table 命令语句
-- @return boolean, doc table 是否成功，成功的话后面跟找到的文档
function ServiceDb.db_findAndModify(self, colname, doc)
    local ret = self.db[colname]:findAndModify(doc)
    if not ret or type(ret.value) ~= 'table' then
        return true, nil
    else
        return true, ret.value
    end
end

--- 查找文档数量
-- @param colname string 集合名
-- @param query table 查询语句
-- @return boolean, count integer 是否成功，成功的话返回数量值
function ServiceDb.db_cound(self, colname, query)
    local cursor = self.db[colname]:find(query)
    local count = cursor:count()
    return true, count
end

--- 查找一个文档
-- @param colname string 集合名
-- @param query table 查询语句
-- @param selector table 查询的字段
-- @param boolean, doc table 是否成功，成功的话后面跟一个文档
function ServiceDb.db_findOne(self, colname, query, selector)
    local doc = self.db[colname]:findOne(query, selector)
    return true, doc
end

--- 查找多个文档
-- @param colname string 集合名
-- @param query table 查询语句
-- @param selector table 查询的字段
-- @param limit integer 限制多少个文档，如果不指定是无限：不建议不指定
-- @param sort table 排序语句:
-- @param skip integer 忽略前面多少个文档
-- @param ok boolean, docs table 是否成功，成功的话后面跟找到的文档
function ServiceDb.db_find(self, colname, query, selector, limit, sort, skip)
--    logger:debug(">>>>>>>>>>>>>>>db_find:%s\t%s", colname, rtl.tostring(query))
    local cursor = self.db[colname]:find(query, selector)
    if sort then
        cursor:sort(sort)
    end
    if skip then
        cursor:skip(skip)
    end
    if limit then
        cursor:limit(limit)
    end
    local docs = {}
    while cursor:hasNext() do
        table.insert(docs, cursor:next())
    end

    return true, docs
end

function ServiceDb.on_start(self)
    ServiceBase.on_start(self)

    -- 连接monggodb
    local conf = service_conf.db_list[self.name]
    local db_conf = {
        host = conf.host,
        port = conf.port,
    }
    local client = mongo.client(db_conf)
    local dbname = "db" .. service_conf.server_id
    self.db = client[dbname]
end

local name = ...
local service_db = ServiceDb(const.service_type.DB, name);
service_db:start()