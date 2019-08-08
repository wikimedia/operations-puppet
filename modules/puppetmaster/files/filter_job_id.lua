if ngx.req.get_method() == "POST" then
  local args, err = ngx.req.get_uri_args()
  if args['command'] == 'replace_catalog' then
    ngx.req.read_body()
    body = ngx.req.get_body_data()
    if string.find(body, '"job_id":null,') then
      body = string.gsub(ngx.req.get_body_data(), '"job_id":null,','')
      ngx.req.set_body_data(body)
    end
  end
end
