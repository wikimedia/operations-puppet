-- SPDX-License-Identifier: Apache-2.0
-- Decide if a request should be routed to mediawiki on k8s or not.
--
-- See https://wikitech.wikimedia.org/wiki/X-Wikimedia-Debug

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)
-- We're mapping the results from multi-dc.lua as we want to process if we're going to k8s *after*
-- multi-dc has been determined
local onprem_to_k8s_cluster_map = {
  ['appservers-ro.discovery.wmnet'] = {host = 'mw-web-ro.discovery.wmnet', port = 4450},
  ['appservers-rw.discovery.wmnet'] = {host = 'mw-web.discovery.wmnet', port = 4450},
  ['api-ro.discovery.wmnet'] = {host = 'mw-api-ext-ro.discovery.wmnet', port = 4447},
  ['api-rw.discovery.wmnet'] = {host = 'mw-api-ext.discovery.wmnet', port = 4447}
}
-- TODO: add a config file like for multi-dc at a later point in time if
-- we want to change this often
local wikis_on_k8s = {
  ['test2.wikipedia.org'] = true, -- T290536#843499
  ['test.wikidata.org'] = true -- T331268
}

local function use_k8s()
  -- For now, we just check by wiki
  local host_raw = ts.client_request.header.Host
  if host_raw == nil then
    return false
  end
  local host = host_raw:lower()

  local do_use_k8s = wikis_on_k8s[host]

  if do_use_k8s ~= nil then
    return do_use_k8s
  end
  return false
end

-- The ATS hook point.
function do_remap()
  local orig_url_host = ts.client_request.get_url_host()
  local k8s_dst = onprem_to_k8s_cluster_map[orig_url_host]
  if k8s_dst ~= nil and use_k8s() then
    ts.client_request.set_url_host(k8s_dst.host)
    ts.client_request.set_url_port(k8s_dst.port)
    return TS_LUA_REMAP_DID_REMAP
  end
  return TS_LUA_REMAP_NO_REMAP
end
