--   Copyright 2020 Bryan Davis <bd808@wikimedia.org>
--   Copyright 2020 Arturo Borrero Gonzalez <aborrero@wikimedia.org>
--   Copyright 2013 Yuvi Panda <yuvipanda@gmail.com>
--
--   Licensed under the Apache License, Version 2.0 (the "License");
--   you may not use this file except in compliance with the License.
--   You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.
--
-- Lua file run by nginx that does appropriate routing

local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(1000)
red:connect('127.0.0.1', 6379)

--- Look up a backend for a given tool
-- @param toolname Name of the tool
-- @param path url URL
function route_backend_and_exit_if_ok(toolname, url)
    local routes_arr = nil
    local route = nil

    if not toolname then
        return
    end

    routes_arr = red:hgetall('prefix:' .. toolname)
    if not routes_arr then
        return
    end

    local routes = red:array_to_hash(routes_arr)
    for pattern, backend in pairs(routes) do
        if ngx.re.match(url, pattern) ~= nil then
            route = backend
            break
        end
    end

    if not route then
        return
    end

    -- Use a connection pool of 256 connections with a 32s idle timeout
    -- This also closes the current redis connection.
    red:set_keepalive(1000 * 32, 256)
    ngx.var.backend = route
    ngx.exit(ngx.OK)
end

--- Generate the redirect URL by checking first for nginx vars for safety
-- @param toolname Name of the tool
-- @param path Path fragment of URL
function compute_redirect_url(toolname, path)
    -- toolname and path were checked in the previous function

    if not ngx.var.canonical_scheme then
        ngx.log(ngx.STDERR, 'ERROR: no $canonical_scheme var defined in nginx conf. This is a Toolforge outage!')
        ngx.log(ngx.STDERR, 'ERROR: the LUA code expects the $canonical_scheme var to be set to "https://"')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if not ngx.var.canonical_domain then
        ngx.log(ngx.STDERR, 'ERROR: no $canonical_domain var defined in nginx conf. This is a Toolforge outage!')
        ngx.log(ngx.STDERR, 'ERROR: the LUA code expects the $canonical_domain var to be set to "toolforge.org"')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local is_args = ''
    if ngx.var.is_args then
        is_args = ngx.var.is_args
    end
    local args = ''
    if ngx.var.args then
        args = ngx.var.args
    end

    return ngx.var.canonical_scheme .. toolname .. '.' .. ngx.var.canonical_domain .. path .. is_args .. args
end

--- Look up a canonical redirect target for a given tool
-- @param toolname Name of the tool
-- @param path Path fragment of the URL
function try_redirect_and_exit_if_ok(toolname, path)
    if not toolname or not path then
        return
    end

    -- check to see if we have a redirect key for this tool, that's all we need
    -- to generate the redirect
    local redirect = red:hgetall('redirect:' .. toolname)
    if not redirect or next(redirect) == nil then
        return
    end

    -- Use a connection pool of 256 connections with a 32s idle timeout
    -- This also closes the current redis connection. At this point we don't
    -- expect any more calls to redis for this end user request.
    red:set_keepalive(1000 * 32, 256)

    -- We are redirecting the following:
    --- from  tools.wmflabs.org/$tool/index.php?param=foo
    --- to    $tool.toolforge.org/index.php?param=foo
    -- redirect happens right here; nothing else is evaluated in the nginx conf
    return ngx.redirect(compute_redirect_url(toolname,path), 307)
end

local subdomain = string.match(ngx.var.http_host, "^[^.]+")
-- case 1: webservices running in the grid using $tool.toolforge.org
route_backend_and_exit_if_ok(subdomain, "/")

-- if no subdomain-based routing was found, then use the legacy routing scheme
local captures = ngx.re.match(ngx.var.uri, "^/([^/]*)(/.*)?$")
local prefix = captures[1]
local rest = captures[2] or "/"
-- case 2: webservices running in the grid using tools.wmflabs.org/$tool
-- case 2: the webservice used --canonical and wants a redirect to toolforge.org
-- case 2: eventually, next request will be for case 1
try_redirect_and_exit_if_ok(prefix, rest)
-- case 3: webservices running in the grid using tools.wmflabs.org/$tool
-- case 3: the webservice didn't use --canonical
route_backend_and_exit_if_ok(prefix, rest)

-- case 4: webservices running in the k8s cluster, or
-- case 4: anything else, the tool-fourohfour webservice will handle it!
ngx.exit(ngx.OK)
