-- SPDX-License-Identifier: Apache-2.0
require("default")

_G.ts = {
  http = {},
  server_response = { header = {} },
  server_request = { header = {} },
  client_response = { header = {} },
  client_request = { header = {} },
}

_G.TS_LUA_CACHE_LOOKUP_MISS = 0
_G.TS_LUA_CACHE_LOOKUP_HIT_FRESH = 1

_G.ts.client_request.get_uri = function() return "/" end
_G.read_config = function() return 'pass-test-hostname' end
_G.ts.server_response.get_status = function() return 200 end
_G.ts.server_response.is_cacheable = function() return true end
_G.ts.server_response.get_maxage = function() return 42 end

describe("Busted unit testing framework", function()
  before_each(function()
      _G.ts.server_request.header = {}
      _G.ts.server_response.header = {}
      _G.ts.client_request.header = {}
      _G.ts.client_response.header = {}
      _G.ts.ctx = {}
      stub(ts.http, "set_server_resp_no_store")
  end)

  describe("script for ATS Lua Plugin", function()
    stub(ts, "debug")
    stub(ts, "error")
    stub(ts, "hook")

    it("test - do_global_read_response 404 TTL cap", function()
      _G.ts.server_response.get_status = function() return 404 end
      _G.ts.server_response.header['Cache-Control'] = nil
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Cache-Control'])

      _G.ts.server_response.get_maxage = function() return 3600 end
      do_global_read_response()
      assert.are.equals('s-maxage=600', _G.ts.server_response.header['Cache-Control'])
    end)

    it("test - do_global_read_response Set-Cookie", function()
      -- Without Set-Cookie
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was_not_called()

      -- With Set-Cookie
      _G.ts.server_response.header['Set-Cookie'] = 'banana potato na'
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was.called_with(1)
    end)

    it("test - do_global_read_response cacheable Cookie", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie does not contain Session / Token
      _G.ts.client_request.header['Cookie'] = 'WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was_not_called()
    end)

    it("test - do_global_read_response uncacheable Cookie but no Vary", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie contains Session / Token but there is no Vary
      _G.ts.client_request.header['Cookie'] = 'centralauth_Token=BANANA; WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was_not_called()
    end)

    it("test - do_global_read_response uncacheable Cookie and not Vary:Cookie", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie contains Session / Token and the response is NOT Vary:Cookie
      _G.ts.server_response.header['Vary'] = 'Accept-Encoding,Authorization'
      _G.ts.client_request.header['Cookie'] = 'centralauth_Token=BANANA; WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was_not_called()
    end)

    it("test - do_global_read_response uncacheable Cookie (Session) and Vary:Cookie", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie contains Session / Token and the response is Vary:Cookie
      _G.ts.server_response.header['Vary'] = 'Accept-Encoding,Cookie,Authorization'
      _G.ts.client_request.header['Cookie'] = 'nlwikiSession=banana; nlwikiUserID=999999; nlwikiUserName=thisisauser'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was.called_with(1)
    end)

    it("test - do_global_read_response uncacheable Cookie (lowercase session) and Vary:Cookie", function()
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      -- Cookie contains Session / Token and the response is Vary:Cookie
      _G.ts.server_response.header['Vary'] = 'Accept-Encoding,Cookie,Authorization'
      _G.ts.client_request.header['Cookie'] = 'dewiki_BPsession=test'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was.called_with(1)
    end)

    it("test - do_global_read_response large Content-Length", function()
      -- No Content-Length
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was_not_called()

      -- Small enough object
      _G.ts.server_response.header['Content-Length'] = '120'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was_not_called()

      -- Large enough object
      _G.ts.server_response.header['Content-Length'] = '1073741825'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was.called_with(1)

      -- PKP headers sanitation
      _G.ts.server_response.header['Public-Key-Pins'] = 'test'
      _G.ts.server_response.header['Public-Key-Pins-Report-Only'] = 'test'
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Public-Key-Pins'])
      assert.are.equals(nil, _G.ts.server_response.header['Public-Key-Pins-Report-Only'])
    end)

    it("test - do_global_read_response 503 error with Cache-Control", function()
      -- 200 response with Cache-Control
      _G.ts.server_response.header['Cache-Control'] = 'public, max-age=10'
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was_not_called()

      -- 503 response with Cache-Control
      _G.ts.server_response.get_status = function() return 503 end
      do_global_read_response()
      assert.stub(ts.http.set_server_resp_no_store).was.called_with(1)
    end)

    it("test - do_global_read_response Vary-slotting for X-Forwarded-Proto", function()
      local old_status = _G.ts.server_response.get_status
      _G.ts.server_response.get_status = function() return 301 end

      _G.ts.server_response.header['Vary'] = nil
      do_global_read_response()
      assert.are.equals('X-Forwarded-Proto', _G.ts.server_response.header['Vary'])

      -- Do not add X-Forwarded-Proto on other status codes
      _G.ts.server_response.get_status = old_status
      _G.ts.server_response.header['Vary'] = nil
      do_global_read_response()
      assert.are.equals(nil, _G.ts.server_response.header['Vary'])
    end)

    it("test - do_global_send_response cache miss", function()
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_MISS end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('pass-test-hostname miss', ts.client_response.header['X-Cache-Int'])
      assert(ts.client_response.header['X-ATS-Timestamp'] > 1567423579)
    end)

    it("test - do_global_send_response cache hit", function()
      _G.ts.http.get_cache_lookup_status = function() return TS_LUA_CACHE_LOOKUP_HIT_FRESH end

      assert.are.equals(0, do_global_send_response())
      assert.are.equals('pass-test-hostname hit', ts.client_response.header['X-Cache-Int'])
    end)

    it("test - do_global_read_request", function()
      stub(ts.http, "config_int_set")
      _G.ts.client_request.header['Accept-Encoding'] = 'gzip'
      do_global_read_request()
      assert.are.equals(nil, _G.ts.client_request.header['Accept-Encoding'])
    end)

    it("test - do_global_post_remap with Session cookie", function()
      local session_cookie = 'nlwikiSession=banana; nlwikiUserID=999999; nlwikiUserName=thisisauser'
      -- Session cookie isn't hidden for cache lookup
      _G.ts.client_request.header['Cookie'] = session_cookie
      do_global_post_remap()
      assert.are_equals(_G.ts.client_request.header['Cookie'], session_cookie)
      assert.stub(ts.hook).was_not_called()
      -- X-Varnish-Cluster doesn't reach the applayer
      assert.are_equals(_G.ts.client_request.header['X-Varnish-Cluster'], nil)
    end)

    it("test - do_global_post_remap Token cookie", function()
      -- Token cookie isn't hidden for cache lookup
      local token_cookie = 'centralauth_Token=BANANA; WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      _G.ts.client_request.header['Cookie'] = token_cookie
      do_global_post_remap()
      assert.are_equals(_G.ts.client_request.header['Cookie'], token_cookie)
      assert.stub(ts.hook).was_not_called()
      -- X-Varnish-Cluster doesn't reach the applayer
      assert.are_equals(_G.ts.client_request.header['X-Varnish-Cluster'], nil)
    end)

    it("test - do_global_post_remap with Random cookie and X-Varnish-Cluster=misc", function()
      -- Random cookie isn't hidden for cache lookup iff X-Varnish-Cluster is set to misc
      local random_cookie = 'foo=bar'
      _G.ts.client_request.header['Cookie'] = random_cookie
      _G.ts.client_request.header['X-Varnish-Cluster'] = 'misc'
      do_global_post_remap()
      assert.are_equals(_G.ts.client_request.header['Cookie'], random_cookie)
      assert.stub(ts.hook).was_not_called()
      -- X-Varnish-Cluster doesn't reach the applayer
      assert.are_equals(_G.ts.client_request.header['X-Varnish-Cluster'], nil)
    end)

    it("test - do_global_post_remap with non Session / Token cookie", function()
      -- cookie is hidden for cache lookup
      local cookie = 'WMF-Last-Access=30-Aug-2019; WMF-Last-Access-Global=30-Aug-2019'
      _G.ts.client_request.header['Cookie'] = cookie
      _G.ts.server_request.header['Cookie'] = cookie
      do_global_post_remap()
      assert.are_equals(_G.ts.client_request.header['Cookie'], nil)
      -- X-Varnish-Cluster doesn't reach the applayer
      assert.are_equals(_G.ts.client_request.header['X-Varnish-Cluster'], nil)
      restore_cookie()
      -- Cookie is restored after cache lookup is completed
      assert.are_equals(_G.ts.client_request.header['Cookie'], cookie)
      hide_cookie_store_response()
      -- Cookie is hidden again to store cache response if needed
      assert.are_equals(_G.ts.server_request.header['Cookie'], nil)
    end)
  end)
end)
