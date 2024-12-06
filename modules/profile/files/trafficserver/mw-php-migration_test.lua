-- SPDX-License-Identifier: Apache-2.0

local file_name = debug.getinfo(1, "S").source:sub(1)
local base_dir = (file_name:reverse():match("/([^@]*)") or ""):reverse()
local mw_php_migration_file = loadfile(base_dir .. "/mw-php-migration.lua")
local mw_php_migration_config_file = loadfile(base_dir .. "/mw-php-migration.lua.conf")

local function make_ts(request)
    ts = {
        client_request = { get_url_host = function() return request.url_host end },
        http = { id = function() return 1 end },
        get_config_dir = function() return base_dir end,
    }
    if request.now ~= nil then
        ts.now = function() return request.now end
    else
        ts.now = function() return os.clock() end
    end
    if request.header ~= nil then
        ts.client_request.header = request.header
    else
        ts.client_request.header = {}
    end
    ts.client_request.set_url_host = function(host) ts.client_request.mapped_host = host end
    ts.client_request.set_url_port = function(port) ts.client_request.mapped_port = port end
    ts.error = function(msg) ts.error_msg = msg end
    return ts
end

local function setup(request, config)
    _G.ts = make_ts(request)
    _G.dofile = function () return config end
    _G.TS_LUA_REMAP_DID_REMAP = "DID_REMAP"
    _G.TS_LUA_REMAP_NO_REMAP = "NO_REMAP"
    return _G.ts
end

local function run(request, config)
    local ts = setup(request, config)
    mw_php_migration_file()
    local result = {}
    result.remap_value = do_remap()
    result.host = ts.client_request.mapped_host
    result.port = ts.client_request.mapped_port
    result.error_msg = ts.error_msg
    return result
end

describe("MediaWiki PHP 8.1 migration script for ATS Lua Plugin", function()
    it("does nothing in the absence of an enrollment cookie", function()
        local result = run(
            { url_host = "mw-web.discovery.wmnet" },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.is_nil(result.error_msg)
    end)

    it("remaps mw-web in the presence of an enrollment cookie", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
        assert.are.same("mw-web-next.discovery.wmnet", result.host)
        assert.are.same(4454, result.port)
        assert.is_nil(result.error_msg)
    end)

    it("remaps mw-web-ro in the presence of an enrollment cookie", function()
        local result = run(
            {
                url_host = "mw-web-ro.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
        assert.are.same("mw-web-next-ro.discovery.wmnet", result.host)
        assert.are.same(4454, result.port)
        assert.is_nil(result.error_msg)
    end)

    it("remaps mw-api-ext in the presence of an enrollment cookie", function()
        local result = run(
            {
                url_host = "mw-api-ext.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
        assert.are.same("mw-api-ext-next.discovery.wmnet", result.host)
        assert.are.same(4455, result.port)
        assert.is_nil(result.error_msg)
    end)

    it("remaps mw-api-ext-ro in the presence of an enrollment cookie", function()
        local result = run(
            {
                url_host = "mw-api-ext-ro.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
        assert.are.same("mw-api-ext-next-ro.discovery.wmnet", result.host)
        assert.are.same(4455, result.port)
        assert.is_nil(result.error_msg)
    end)

    it("treats the enrollment cookie as case-sensitive", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PhP_eNgInE=8.1" }
            },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.is_nil(result.error_msg)
    end)

    it("ignores nonsense values of the enrollment cookie", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=nope" }
            },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.is_nil(result.error_msg)
    end)

    it("respects the load_fraction override read from config", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            { load_fraction = 0 }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.is_nil(result.error_msg)
    end)

    it("respects the load_fraction override read from config upon reload", function()
        local ts_initial = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" },
                now = 0
            },
            { load_fraction = 1 }
        )

        mw_php_migration_file()

        assert.are.same(TS_LUA_REMAP_DID_REMAP, do_remap())
        assert.are.same("mw-web-next.discovery.wmnet", ts_initial.client_request.mapped_host)
        assert.are.same(4454, ts_initial.client_request.mapped_port)
        assert.is_nil(ts_initial.error_msg)

        local ts_reload = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" },
                now = 11  -- The config reload interval is 10s.
            },
            { load_fraction = 0 }
        )

        assert.are.same(TS_LUA_REMAP_NO_REMAP, do_remap())
        assert.is_nil(ts_reload.client_request.mapped_host)
        assert.is_nil(ts_reload.client_request.mapped_port)
        assert.is_nil(ts_reload.error_msg)
    end)

    it("raises an error and does not remap if the original host is not recognized", function()
        local result = run(
            {
                url_host = "lol-what.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            { load_fraction = 1 }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.has.match("unrecognized original host", result.error_msg)
    end)

    it("raises an error and uses the default config if the initial config cannot be loaded", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            { load_fraction = "clearly not a number" }
        )
        assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
        assert.are.same("mw-web-next.discovery.wmnet", result.host)
        assert.are.same(4454, result.port)
        assert.has.match("invalid config file", result.error_msg)
    end)

    it("raises an error and leaves config untouched if the new config cannot be loaded", function()
        local ts_initial = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" },
                now = 0
            },
            { load_fraction = 1 }
        )

        mw_php_migration_file()

        assert.are.same(TS_LUA_REMAP_DID_REMAP, do_remap())
        assert.are.same("mw-web-next.discovery.wmnet", ts_initial.client_request.mapped_host)
        assert.are.same(4454, ts_initial.client_request.mapped_port)
        assert.is_nil(ts_initial.error_msg)

        local ts_reload = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" },
                now = 11  -- The config reload interval is 10s.
            },
            { load_fraction = "clearly not a number" }
        )

        assert.are.same(TS_LUA_REMAP_DID_REMAP, do_remap())
        assert.are.same("mw-web-next.discovery.wmnet", ts_reload.client_request.mapped_host)
        assert.are.same(4454, ts_reload.client_request.mapped_port)
        assert.has.match("invalid config file", ts_reload.error_msg)
    end)

    it("emits no errors when using the production config", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = "PHP_ENGINE=8.1" }
            },
            mw_php_migration_config_file()
        )
        -- We do not care about the remapping outcome, only whether errors
        -- were emitted that indicate the production config is invalid.
        assert.is_nil(result.error_msg)
    end)
end)
