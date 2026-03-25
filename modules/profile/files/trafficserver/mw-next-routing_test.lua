-- SPDX-License-Identifier: Apache-2.0

local file_name = debug.getinfo(1, "S").source:sub(1)
local base_dir = (file_name:reverse():match("/([^@]*)") or ""):reverse()
local mw_next_routing_file = loadfile(base_dir .. "/mw-next-routing.lua")
local mw_next_routing_config_file = loadfile(base_dir .. "/mw-next-routing.lua.conf")

local function make_client_request(params)
    client_request = { get_url_host = function() return params.url_host end }
    if params.header ~= nil then
        client_request.header = params.header
    else
        client_request.header = {}
    end
    client_request.set_url_host = function(host) ts.client_request.mapped_host = host end
    client_request.set_url_port = function(port) ts.client_request.mapped_port = port end
    return client_request
end

local function make_ts(params)
    ts = {
        client_request = make_client_request(params),
        http = { id = function() return 1 end },
        get_config_dir = function() return base_dir end,
    }
    if params.now ~= nil then
        ts.now = function() return params.now end
    else
        ts.now = function() return os.clock() end
    end
    ts.error = function(msg) ts.error_msg = msg end
    return ts
end

local function setup(params, config)
    _G.ts = make_ts(params)
    _G.dofile = function () return config end
    _G.TS_LUA_REMAP_DID_REMAP = "DID_REMAP"
    _G.TS_LUA_REMAP_NO_REMAP = "NO_REMAP"
    return _G.ts
end

local function run(params, config)
    local ts = setup(params, config)
    mw_next_routing_file()
    local result = {}
    result.remap_value = do_remap()
    result.host = ts.client_request.mapped_host
    result.port = ts.client_request.mapped_port
    result.error_msg = ts.error_msg
    return result
end

-- The cookie value that will enroll requests in -next routing.
local ENROLLABLE_COOKIE = "ANIMAL=Unicorn"

-- enrollable_requests is a table mapping from test scenario description to
-- params table modifier function. The params table should be modified such
-- that make_client_request will return a request enrollable in next routing.
local enrollable_requests = {
    ["eligible cookie present with a correct value"] = function(params)
        params.header = { Cookie = ENROLLABLE_COOKIE }
        return params
    end,
    ["eligible cookie present with a correct value as substring"] = function(params)
        params.header = {
            Cookie = "Something; " .. ENROLLABLE_COOKIE .. "; SomethingElse"
        }
        return params
    end,
}

-- non_enrollable_requests is a table mapping from test scenario description to
-- params table modifier function. The params table should be modified such that
-- make_client_request will return a request *not* enrollable in next routing.
local non_enrollable_requests = {
    ["no eligible cookie present"] = function(params) return params end,
    ["eligible cookie present with an incorrect value"] = function(params)
        params.header = { Cookie = "ANIMAL=PointyHorse" }
        return params
    end,
}

describe("MediaWiki -next routing script for ATS Lua Plugin", function()
    -- Parametrized tests for the no-remapping case.
    describe("does not remap", function()
        local it_does_not_remap = function(host)
            for scenario, request_params in pairs(non_enrollable_requests) do
                it(host .. " when " .. scenario, function()
                    local result = run(
                        request_params({ url_host = host }),
                        {
                            enabled = true,
                            load_fraction = 1,
                            cookie_pattern = ENROLLABLE_COOKIE
                        }
                    )
                    assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
                    assert.is_nil(result.host)
                    assert.is_nil(result.port)
                    assert.is_nil(result.error_msg)
                end)
            end
        end

        it_does_not_remap("mw-web.discovery.wmnet")
        it_does_not_remap("mw-web-ro.discovery.wmnet")
        it_does_not_remap("mw-api-ext.discovery.wmnet")
        it_does_not_remap("mw-api-ext-ro.discovery.wmnet")
    end)

    -- Parametrized tests for the remapping case.
    describe("does remap", function()
        local it_does_remap = function(host, remap_host, remap_port)
            for scenario, request_params in pairs(enrollable_requests) do
                it(host .. " when " .. scenario, function()
                    local result = run(
                        request_params({ url_host = host }),
                        {
                            enabled = true,
                            load_fraction = 1,
                            cookie_pattern = ENROLLABLE_COOKIE
                        }
                    )
                    assert.are.same(TS_LUA_REMAP_DID_REMAP, result.remap_value)
                    assert.are.same(remap_host, result.host)
                    assert.are.same(remap_port, result.port)
                    assert.is_nil(result.error_msg)
                end)
            end
        end

        it_does_remap("mw-web.discovery.wmnet", "mw-web-next.discovery.wmnet", 4454)
        it_does_remap("mw-web-ro.discovery.wmnet", "mw-web-next-ro.discovery.wmnet", 4454)
        it_does_remap("mw-api-ext.discovery.wmnet", "mw-api-ext-next.discovery.wmnet", 4455)
        it_does_remap("mw-api-ext-ro.discovery.wmnet", "mw-api-ext-next-ro.discovery.wmnet", 4455)
    end)

    it("respects the enabled override read from config", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = ENROLLABLE_COOKIE }
            },
            {
                enabled = false,
                load_fraction = 1,
                cookie_pattern = ENROLLABLE_COOKIE
            }
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
                header = { Cookie = ENROLLABLE_COOKIE }
            },
            {
                enabled = true,
                load_fraction = 0,
                cookie_pattern = ENROLLABLE_COOKIE
            }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.is_nil(result.error_msg)
    end)

    it("respects the new config upon reload", function()
        local ts_initial = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = ENROLLABLE_COOKIE },
                now = 0
            },
            {
                enabled = true,
                load_fraction = 1,
                cookie_pattern = ENROLLABLE_COOKIE
            }
        )

        mw_next_routing_file()

        assert.are.same(TS_LUA_REMAP_DID_REMAP, do_remap())
        assert.are.same("mw-web-next.discovery.wmnet", ts_initial.client_request.mapped_host)
        assert.are.same(4454, ts_initial.client_request.mapped_port)
        assert.is_nil(ts_initial.error_msg)

        local ts_reload = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = ENROLLABLE_COOKIE },
                now = 11  -- The config reload interval is 10s.
            },
            {
                enabled = true,
                load_fraction = 0,
                cookie_pattern = ENROLLABLE_COOKIE
            }
        )

        assert.are.same(TS_LUA_REMAP_NO_REMAP, do_remap())
        assert.is_nil(ts_reload.client_request.mapped_host)
        assert.is_nil(ts_reload.client_request.mapped_port)
        assert.is_nil(ts_reload.error_msg)
    end)

    it("does not remap if the original host is not recognized", function()
        local result = run(
            {
                url_host = "lol-what.discovery.wmnet",
                header = { Cookie = ENROLLABLE_COOKIE }
            },
            {
                enabled = true,
                load_fraction = 1,
                cookie_pattern = ENROLLABLE_COOKIE
            }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.is_nil(result.error_msg)
    end)

    it("raises an error and uses the default config if the initial config cannot be loaded", function()
        local result = run(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = ENROLLABLE_COOKIE }
            },
            {
                enabled = true,
                load_fraction = "clearly not a number",
                cookie_pattern = ENROLLABLE_COOKIE
            }
        )
        assert.are.same(TS_LUA_REMAP_NO_REMAP, result.remap_value)
        assert.is_nil(result.host)
        assert.is_nil(result.port)
        assert.has.match("invalid config file", result.error_msg)
    end)

    it("raises an error and leaves config untouched if the new config cannot be loaded", function()
        local ts_initial = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = ENROLLABLE_COOKIE },
                now = 0
            },
            {
                enabled = true,
                load_fraction = 1,
                cookie_pattern = ENROLLABLE_COOKIE
            }
        )

        mw_next_routing_file()

        assert.are.same(TS_LUA_REMAP_DID_REMAP, do_remap())
        assert.are.same("mw-web-next.discovery.wmnet", ts_initial.client_request.mapped_host)
        assert.are.same(4454, ts_initial.client_request.mapped_port)
        assert.is_nil(ts_initial.error_msg)

        local ts_reload = setup(
            {
                url_host = "mw-web.discovery.wmnet",
                header = { Cookie = ENROLLABLE_COOKIE },
                now = 11  -- The config reload interval is 10s.
            },
            {
                enabled = true,
                load_fraction = "clearly not a number",
                cookie_pattern = ENROLLABLE_COOKIE
            }
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
                header = { Cookie = ENROLLABLE_COOKIE }
            },
            mw_next_routing_config_file()
        )
        -- We do not care about the remapping outcome, only whether errors
        -- were emitted that indicate the production config is invalid.
        assert.is_nil(result.error_msg)
    end)
end)

describe("config file", function()
  it("should be free of syntax errors", function()
    local chunk, err = loadfile(base_dir .. "/mw-next-routing.lua.conf")
    assert.is_nil(err, "mw-next-routing.lua.conf has a syntax error: " .. tostring(err))
    assert.is_not_nil(chunk, "mw-next-routing.lua.conf could not be loaded")
  end)
end)
