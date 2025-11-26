-- SPDX-License-Identifier: Apache-2.0
-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

-- Beta Cluster-specific logic, which runs before rb-mw-mangling.lua
function remap_hook()
    local orig_path = ts.client_request.get_uri()

    -- w.beta.wmcloud.org URL shortener rewrite T396012
    if ts.client_request.header['Host'] == "w.beta.wmcloud.org" and orig_path ~= "/" then
        ts.client_request.header['Host'] = "en.wikipedia.beta.wmcloud.org"
        ts.client_request.set_uri("/wiki/Special:UrlRedirector" .. orig_path)
        return
    end
end

-- Simplified version of REST Gateway for the Beta Cluster
--
-- Production version:
-- * ./gateway-check.lua
-- * ./gateway-check.lua.conf
-- * https://gerrit.wikimedia.org/g/operations/deployment-charts/+/HEAD/helmfile.d/services/rest-gateway/values.yaml
--
-- Bigger picture, in order of execution:
-- 1. profile::trafficserver::backend::mapping_rules
--    We regex_map `http://(.*)/api/rest_v1` to a RESTBase instance.
--    That sets a tentative destination (which we override below),
--    and does not change Host header or URL.
-- 2. ./gateway-check.lua
--    Not enabled in Beta Cluster.
-- 3. ./rb-mw-mangling-beta.lua [This code]
--    As part of RESTBase sunsetting, we set the destination for some
--    endpoints directly to their backend, instead via RESTBase (T402206).
-- 4. ./rb-mw-mangling.lua
--    We finish mangling the URL to `/:domain/v1/`
local function use_rest_gateway()
    local orig_path = ts.client_request.get_uri()

    -- Based on gateway-check.lua.conf#defaults
    local gateway_paths = {
        ["/api/rest_v1/page/summary/(.*)"] = {"deployment-docker-mobileapps02.deployment-prep.eqiad1.wikimedia.cloud", 8888},
    }

    -- Based on gateway-check.lua#use_rest_gateway
    for key, value in pairs(gateway_paths) do
        if string.find(orig_path, key) then
            return value
        end
    end
end

function do_remap()
    -- Use TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, so that the mangling happens
    -- after cache lookup and before fetching the response from the origin
    ts.hook(TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, remap_hook)

    local use_gateway = use_rest_gateway()
    if use_gateway then
        ts.client_request.set_url_host(use_gateway[1])
        ts.client_request.set_url_port(use_gateway[2])
        return TS_LUA_REMAP_DID_REMAP
    end

    return TS_LUA_REMAP_NO_REMAP
end
