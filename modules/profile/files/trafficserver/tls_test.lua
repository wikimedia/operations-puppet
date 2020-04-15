require "tls"

_G.ts = {
  http = {},
  server_request = { header = {} },
  client_request = { client_addr = {}, header = {} },
  client_response = { header = {} },
}

_G.ts.client_request.client_addr.get_addr = function() return "127.0.0.1", 1234, 2 end
_G.ts.client_request.get_ssl_reused = function() return 0 end
_G.ts.client_request.get_ssl_protocol = function() return "TLSv1.2" end
_G.ts.client_request.get_ssl_cipher = function() return "ECDHE-ECDSA-AES256-GCM-SHA384" end
_G.ts.client_request.get_ssl_curve = function() return "X25519" end
_G.get_websocket_support = function() return false end
_G.get_keepalive_support = function() return false end

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()
    stub(ts, "debug")
    stub(ts, "hook")
    stub(ts.http, "config_int_set")

    it("test - do_global_send_request", function()

      -- With HTTP2 in the stack
      _G.ts.http.get_client_protocol_stack = function() return "ipv4", "tcp", "tls/1.2", "h2" end
      _G.ts.server_request.header['Proxy-Connection'] = 'close'
      do_global_send_request()
      assert.are.equals('127.0.0.1', _G.ts.server_request.header['X-Client-IP'])
      assert.are.equals('vers=TLSv1.2;keyx=X25519;auth=ECDSA;ciph=AES256-GCM-SHA384;prot=h2;sess=new', _G.ts.server_request.header['X-Analytics-TLS'])
      assert.are.equals('H2=1; SSR=0; SSL=TLSv1.2; C=ECDHE-ECDSA-AES256-GCM-SHA384; EC=X25519;', _G.ts.server_request.header['X-Connection-Properties'])
      assert.are.equals('close', _G.ts.server_request.header['Connection'])
      assert.are.equals('https', _G.ts.server_request.header['X-Forwarded-Proto'])
      assert.is_nil(_G.ts.server_request.header['Proxy-Connection'])

      -- With TLSv1.3 and HTTP2
      _G.ts.client_request.get_ssl_protocol = function() return "TLSv1.3" end
      _G.ts.client_request.get_ssl_cipher = function() return "TLS_CHACHA20_POLY1305_SHA256" end
      _G.ts.client_request.get_ssl_curve = function() return "X25519" end
      do_global_send_request()
      assert.are.equals('vers=TLSv1.3;keyx=X25519;auth=ECDSA;ciph=CHACHA20-POLY1305-SHA256;prot=h2;sess=new', _G.ts.server_request.header['X-Analytics-TLS'])
      assert.are.equals('H2=1; SSR=0; SSL=TLSv1.3; C=TLS_CHACHA20_POLY1305_SHA256; EC=X25519;', _G.ts.server_request.header['X-Connection-Properties'])

      -- With HTTP1.1 in the stack
      _G.ts.http.get_client_protocol_stack = function() return "ipv4", "tcp", "tls/1.2", "http/1.1" end
      _G.ts.client_request.get_ssl_protocol = function() return "TLSv1.2" end
      _G.ts.client_request.get_ssl_cipher = function() return "ECDHE-ECDSA-AES256-GCM-SHA384" end
      _G.ts.client_request.get_ssl_curve = function() return "X25519" end
      do_global_send_request()
      assert.are.equals('vers=TLSv1.2;keyx=X25519;auth=ECDSA;ciph=AES256-GCM-SHA384;prot=h1;sess=new', _G.ts.server_request.header['X-Analytics-TLS'])
      assert.are.equals('H2=0; SSR=0; SSL=TLSv1.2; C=ECDHE-ECDSA-AES256-GCM-SHA384; EC=X25519;', _G.ts.server_request.header['X-Connection-Properties'])

      -- With keepalive enabled
      _G.get_keepalive_support = function() return true end
      do_global_send_request()
      assert.are.equals('keep-alive', _G.ts.server_request.header['Connection'])

      -- With websocket support disabled and client requesting a connection upgrade
      _G.get_keepalive_support = function() return false end
      _G.ts.client_request.header['Upgrade'] = 'websocket'
      _G.ts.client_request.header['Connection'] = 'Upgrade'
      do_global_send_request()
      assert.is_nil(_G.ts.server_request.header['Upgrade'])
      assert.are.equals('close', _G.ts.server_request.header['Connection'])
      assert.stub(ts.http.config_int_set).was_not_called()

      -- With websocket support enabled but client doesn't request an upgrade
      _G.get_websocket_support = function() return true end
      _G.ts.client_request.header['Upgrade'] = nil
      _G.ts.client_request.header['Connection'] = nil
      do_global_send_request()
      assert.is_nil(_G.ts.server_request.header['Upgrade'])
      assert.are.equals('close', _G.ts.server_request.header['Connection'])
      assert.stub(ts.http.config_int_set).was_not_called()

      -- With websocket support enabled and client requests an upgrade
      _G.get_websocket_support = function() return true end
      _G.ts.client_request.header['Upgrade'] = 'websocket'
      _G.ts.client_request.header['Connection'] = 'Upgrade'
      do_global_send_request()
      assert.are.equals('websocket', _G.ts.server_request.header['Upgrade'])
      assert.are.equals('Upgrade', _G.ts.server_request.header['Connection'])
      assert.stub(ts.http.config_int_set).was_called_with(TS_LUA_CONFIG_HTTP_KEEP_ALIVE_ENABLED_OUT, 0)
    end)

    it("test - do_global_send_response", function()
      _G.ts.client_response.header['X-Analytics'] = 'https=1;nocookies=1'
      _G.ts.client_response.header['X-Envoy-Upstream-Service-Time'] = '42'
      do_global_send_response()
      assert.is_nil(_G.ts.client_response.header['X-Analytics'])
      assert.is_nil(_G.ts.client_response.header['X-Envoy-Upstream-Service-Time'])

      _G.ts.client_response.header['X-Analytics'] = 'https=1;nocookies=1'
      _G.ts.client_response.header['X-Envoy-Upstream-Service-Time'] = '42'
      _G.ts.client_request.header['X-Wikimedia-Debug'] = 'mwdebug1001.eqiad.wmnet'
      do_global_send_response()
      assert.is_nil(_G.ts.client_response.header['X-Analytics'])
      assert.are.equals(_G.ts.client_response.header['X-Envoy-Upstream-Service-Time'], '42')
    end)
  end)
end)
