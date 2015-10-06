-- Translates POST to GET
if ngx.var.request_method == "POST" then
    ngx.req.read_body()
    local args = ngx.req.get_post_args()
    if not args then
        ngx.say("failed to get post args: ", err)
        return
    end
    res = ngx.location.capture('/bigdata/namespace/wdq/sparql', {args = args, method = ngx.HTTP_GET})
    if res.status ~= ngx.HTTP_OK then
        ngx.status = res.status
        ngx.print(res.body)
        ngx.exit(res.status)
    end
    ngx.print(res.body)
else
    local args = ngx.req.get_uri_args()
    ngx.exec('/bigdata/namespace/wdq/sparl', args)
end
