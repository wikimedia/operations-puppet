if ngx.req.get_method() == "POST" then
  ngx.req.read_body()
  local body = ngx.req.get_body_data()
  body = string.gsub(body, '"job_id":null,','')
  ngx.req.set_body_data(body)
end
