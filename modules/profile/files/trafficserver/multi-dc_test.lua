-- SPDX-License-Identifier: Apache-2.0
local file_name = debug.getinfo(1, "S").source:sub(1)
local base_dir = (file_name:reverse():match("/([^@]*)") or ""):reverse()
local multi_dc_file = loadfile(base_dir .. "/multi-dc.lua")

local function make_ts(mock_request)
  local ts = {}

  function ts.get_config_dir()
    return base_dir
  end

  function ts.error(msg)
    error(msg)
  end

  function ts.now()
    return os.clock()
  end


  ts.http = {}

  function ts.http.id()
    return 1
  end

  ts.client_request = mock_request

  function ts.client_request.get_method()
    return mock_request.method
  end

  function ts.client_request.get_uri_args()
    return mock_request.uri_args
  end

  function ts.client_request.get_uri()
    return mock_request.uri
  end

  function ts.client_request.set_url_host(host)
    ts.client_request.result_host = host
  end

  function ts.client_request.get_url_host()
    return mock_request.url_host
  end

  ts.remap = {}

  function ts.remap.get_to_url_host()
    return mock_request.url_host
  end

  return ts
end

local function run(mock_config, mock_request)
  mock_request.result_host = "host"

  _G.ts = make_ts(mock_request)
  _G.dofile = function ()
    return mock_config
  end

  multi_dc_file()
  do_remap()
  return mock_request.result_host
end

describe("Multi-DC router", function ()

  it("does nothing", function ()
    local result = run(
      {default = {mode = "primary"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("does something", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host-ro", result)
  end)

  it("does something when the host has a dot in it", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host.discovery.wmnet",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host-ro.discovery.wmnet", result)
  end)

  it("respects zero probability", function ()
    local result = run(
      {default = {mode = "local", load = 0}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("respects 100% probability", function ()
    local result = run(
      {default = {mode = "local", load = 1}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host-ro", result)
  end)

  it("handles anons in local-anon mode", function ()
    local result = run(
      {default = {mode = "local-anon"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host-ro", result)
  end)

  it("dispatches logged-in users in local-anon mode", function ()
    local result = run(
      {default = {mode = "local-anon"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
          Cookie = "enwikiSession=abcde"
        }
      }
    )
    assert.are.same("host", result)
  end)

  it("dispatches token-holding users in local-anon mode", function ()
    local result = run(
      {default = {mode = "local-anon"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
          Cookie = "foo=bar; enwikiToken=abcde"
        }
      }
    )
    assert.are.same("host", result)
  end)

  it("dispatches PUT requests to the primary", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "PUT",
        uri_args = "",
        uri = "/w/index.php",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("handles PUT requests locally if they promise to be good", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "PUT",
        uri_args = "",
        uri = "/w/index.php",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
          ["Promise-Non-Write-API-Action"] = "true"
        }
      }
    )
    assert.are.same("host-ro", result)
  end)

  it("dispatches POST requests to the primary", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "POST",
        uri_args = "",
        uri = "/w/index.php",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("handles POST requests locally if they promise to be good", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "POST",
        uri_args = "",
        uri = "/w/index.php",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
          ["Promise-Non-Write-API-Action"] = "true"
        }
      }
    )
    assert.are.same("host-ro", result)
  end)

  it("respects the cookie pin", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
          Cookie = "UseDC=master"
        }
      }
    )
    assert.are.same("host", result)
  end)

  it("respects cpPosIndex", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "cpPosIndex=1",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends rollback", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "action=rollback",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("respects rollback at the end", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "title=Foo&action=rollback",
        uri = "/w/index.php",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("respects rollback in the middle", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "title=Foo&action=rollback&bot=1",
        uri = "/w/index.php",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("doesn't get confused by rollback in other places", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "title=Foo=action=rollback",
        uri = "/w/index.php",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host-ro", result)
  end)

  it("sends Special:CentralAutoLogin on local domain", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Special:CentralAutoLogin/setCookies",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends Special:CentralAutoLogin on shared domain", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/enwiki/wiki/Special:CentralAutoLogin/checkLoggedIn",
        url_host = "host",
        header = {Host = "auth.wikimedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends Special:CentralLogin on local domain", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Special:CentralLogin/complete",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends Special:CentralLogin on shared domain", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/enwiki/wiki/Special:CentralLogin/start",
        url_host = "host",
        header = {Host = "auth.wikimedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends action=centralauthtoken", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "action=centralauthtoken",
        uri = "/w/api.php",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends centralauthtoken=something", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "action=query&centralauthtoken=something",
        uri = "/w/api.php",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends Authorization: CentralAuthToken", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/w/rest.php/foo/bar",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
          Authorization = "CentralAuthToken;123456678"
        }
      }
    )
    assert.are.same("host", result)
  end)

  it("respects a domain override", function ()
    local result = run(
      {
        default = {
          mode = "primary"
        },
        domains = {
          ["test.wikipedia.org"] = {
            mode = "local"
          }
        },
      },
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "test.wikipedia.org"}
      }
    )
    assert.are.same("host-ro", result)
  end)

  it("ignores an unrelated domain override", function ()
    local result = run(
      {
        default = {
          mode = "primary"
        },
        domains = {
          ["test.wikipedia.org"] = {
            mode = "local"
          }
        },
      },
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Foo",
        url_host = "host",
        header = {Host = "en.wikipedia.org"}
      }
    )
    assert.are.same("host", result)
  end)

  it("sends Special:OAuth/initiate", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "title=Special:OAuth/initiate&format=json&oauth_callback=oob",
        uri = "/w/index.php",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
        }
      }
    )
    assert.are.same("host", result)
  end)

  it("sends Special:OAuth/authorize", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/wiki/Special:OAuth/authorize",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
        }
      }
    )
    assert.are.same("host", result)
  end)

  it("sends Special:OAuth/token", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "title=Special:OAuth/token&format=json",
        uri = "/w/index.php",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
        }
      }
    )
    assert.are.same("host", result)
  end)

  it("sends REST authorize", function ()
    local result = run(
      {default = {mode = "local"}},
      {
        method = "GET",
        uri_args = "",
        uri = "/w/rest.php/oauth2/authorize",
        url_host = "host",
        header = {
          Host = "en.wikipedia.org",
        }
      }
    )
    assert.are.same("host", result)
  end)

end)

describe("config file", function()
  it("should be free of syntax errors", function()
    local chunk, err = loadfile(base_dir .. "/multi-dc.lua.conf")
    assert.is_nil(err, "multi-dc.lua.conf has a syntax error: " .. tostring(err))
    assert.is_not_nil(chunk, "multi-dc.lua.conf could not be loaded")
  end)
end)
