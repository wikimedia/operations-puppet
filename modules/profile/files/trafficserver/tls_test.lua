require "tls"

_G.ts = {
  http = {},
  server_request = { header = {} },
  client_request = { client_addr = {}, header = {} },
}

_G.ts.client_request.client_addr.get_addr = function() return "127.0.0.1", 1234, 2 end
_G.ts.client_request.get_ssl_reused = function() return 0 end
_G.ts.client_request.get_ssl_protocol = function() return "TLSv1.2" end
_G.ts.client_request.get_ssl_cipher = function() return "ECDHE-ECDSA-AES256-GCM-SHA384" end
_G.ts.client_request.get_ssl_curve = function() return "X25519" end
_G.get_websocket_support = function() return false end

describe("Busted unit testing framework", function()
  describe("script for ATS Lua Plugin", function()
    stub(ts, "debug")
    stub(ts, "hook")

    it("test - do_global_send_request", function()

      -- With HTTP2 in the stack
      _G.ts.http.get_client_protocol_stack = function() return "ipv4", "tcp", "tls/1.2", "h2" end
      _G.ts.server_request.header['Proxy-Connection'] = 'close'
      do_global_send_request()
      assert.are.equals('127.0.0.1', _G.ts.server_request.header['X-Client-IP'])
      assert.are.equals('H2=1; SSR=0; SSL=TLSv1.2; C=ECDHE-ECDSA-AES256-GCM-SHA384; EC=X25519;', _G.ts.server_request.header['X-Connection-Properties'])
      assert.are.equals('close', _G.ts.server_request.header['Connection'])
      assert.are.equals('https', _G.ts.server_request.header['X-Forwarded-Proto'])
      assert.is_nil(_G.ts.server_request.header['Proxy-Connection'])

      -- With HTTP1.1 in the stack
      _G.ts.http.get_client_protocol_stack = function() return "ipv4", "tcp", "tls/1.2", "http/1.1" end
      do_global_send_request()
      assert.are.equals('H2=0; SSR=0; SSL=TLSv1.2; C=ECDHE-ECDSA-AES256-GCM-SHA384; EC=X25519;', _G.ts.server_request.header['X-Connection-Properties'])

      -- With websocket support disabled and client requesting a connection upgrade
      _G.ts.client_request.header['Upgrade'] = 'websocket'
      _G.ts.client_request.header['Connection'] = 'Upgrade'
      do_global_send_request()
      assert.is_nil(_G.ts.server_request.header['Upgrade'])
      assert.are.equals('close', _G.ts.server_request.header['Connection'])

      -- With websocket support enabled but client doesn't request an upgrade
      _G.get_websocket_support = function() return true end
      _G.ts.client_request.header['Upgrade'] = nil
      _G.ts.client_request.header['Connection'] = nil
      do_global_send_request()
      assert.is_nil(_G.ts.server_request.header['Upgrade'])
      assert.are.equals('close', _G.ts.server_request.header['Connection'])

      -- With websocket support enabled and client requests an upgrade
      _G.get_websocket_support = function() return true end
      _G.ts.client_request.header['Upgrade'] = 'websocket'
      _G.ts.client_request.header['Connection'] = 'Upgrade'
      do_global_send_request()
      assert.are.equals('websocket', _G.ts.server_request.header['Upgrade'])
      assert.are.equals('Upgrade', _G.ts.server_request.header['Connection'])
    end)
  end)
end)
