-- SPDX-License-Identifier: Apache-2.0
-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

function remap_hook()
    local orig_uri = ts.client_request.get_uri()

    -- RESTBase mangling
    --
    -- 1. In Varnish (cluster_fe_recv_pre_purge) we replace mobile hostnames
    --    with canonical hostnames on requests to /api/rest_v1/.
    --    That improves caching as RESTBase responses don't vary by m-dot.
    -- 2. In profile::trafficserver::backend::mapping_rules
    --    we first apply a regex_map for `http://(.*)/api/rest_v1`
    --    to direct these at the RESTBase service. That leaves the
    --    Host header and URL path unchanged, thus briefly forming
    --    an invalid RESTBase request with /api/rest_v1.
    -- 3. [This code] We finish mangling the URL to `/:domain/v1/`
    if string.match(orig_uri, "^/api/rest_v1/") then
        local host = ts.client_request.header['Host']
        new_path = "/" .. host .. string.gsub(orig_uri, "^/api/rest_v1/", "/v1/")
        ts.client_request.set_uri(new_path)
        return
    end

    -- Rewrite MediaWiki requests from mobile m-dot domains to canonical
    --
    -- 1. In Varnish (cluster_fe_recv_pre_purge) we compute the canonical hostname
    --    on m-dot requests in the x-dt-host field. We do not replace it there,
    --    because responses/caches must vary.
    -- 2. [This code] Replaces the Host header, because MediaWiki requires canonical
    --    hostnames, and the X-Subdomain header activates MobileFrontend.
    if ts.client_request.header['X-Subdomain'] then
        ts.client_request.header['Host'] = ts.client_request.header['x-dt-host']
        return
    end

    -- w.wiki URL shortener rewrite to meta T133485
    if ts.client_request.header['Host'] == "w.wiki" and orig_uri ~= "/" then
        ts.client_request.header['Host'] = "meta.wikimedia.org"
        ts.client_request.set_uri("/wiki/Special:UrlRedirector" .. orig_uri)
        return
    end
end

function do_remap()
    -- Use TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, so that the mangling happens
    -- after cache lookup and before fetching the response from the origin
    ts.hook(TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, remap_hook)
    return 0
end
