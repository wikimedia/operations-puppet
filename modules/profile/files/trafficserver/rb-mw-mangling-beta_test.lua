-- SPDX-License-Identifier: Apache-2.0

local function make_ts(request)
  ts = {
    client_request = {
      header = {
        Host = request.host
      },
      get_uri = function() return request.uri end,
      set_uri = function(uri) request.uri = uri end,
      set_url_host = function(host) ts.client_request.mapped_host = host end,
      set_url_port = function(port) ts.client_request.mapped_port = port end,
    },
  }

  stub(ts, 'hook')

  return ts
end

describe('rb-mw-mangling-beta', function()
  before_each(function ()
    _G.TS_LUA_REMAP_DID_REMAP = 'DID_REMAP'
    _G.TS_LUA_REMAP_NO_REMAP = 'NO_REMAP'
    _G.ts = nil
  end)

  it('do_remap [Main_Page]', function()
    _G.ts = make_ts({
      host = 'en.wikipedia.beta.wmcloud.org',
      uri = '/wiki/Main_Page'
    })

    require('rb-mw-mangling-beta')
    local result = do_remap()
    remap_hook()

    assert.equals('NO_REMAP', result)
    assert.stub(ts.hook).was.called_with(TS_LUA_HOOK_POST_REMAP, remap_hook)
    assert.equals(nil, ts.client_request.mapped_host)
  end)

  it('do_remap [rest-gateway PCS]', function()
    _G.ts = make_ts({
      host = 'en.wikipedia.beta.wmcloud.org',
      uri = '/api/rest_v1/page/summary/Test'
    })

    require('rb-mw-mangling-beta')
    local result = do_remap()
    remap_hook()

    assert.equals('DID_REMAP', result)
    assert.equals('en.wikipedia.beta.wmcloud.org', ts.client_request.header['Host'])
    assert.equals('/api/rest_v1/page/summary/Test', ts.client_request.get_uri())
    assert.equals('deployment-docker-mobileapps02.deployment-prep.eqiad1.wikimedia.cloud', ts.client_request.mapped_host)
  end)

  it('remap_hook [UrlShortener]', function()
    _G.ts = make_ts({
      host = 'w.beta.wmcloud.org',
      uri = '/A'
    })

    require('rb-mw-mangling-beta')
    local result = do_remap()
    remap_hook()

    assert.equals('NO_REMAP', result)
    assert.equals('en.wikipedia.beta.wmcloud.org', ts.client_request.header['Host'])
    assert.equals('/wiki/Special:UrlRedirector/A', ts.client_request.get_uri())
    assert.equals(nil, ts.client_request.mapped_host)
  end)
end)
