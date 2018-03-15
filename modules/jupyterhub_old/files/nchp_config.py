"""
Configuration for JupyterHub NGINX configurable-http-proxy

We use this rather than the nodejs based one.

We configure it to bind on public interfaces with port 8000,
and only on localhost for the API. We also direct all default
traffic to 8081 on localhost, which is where the jupyterhub is
listening.
"""

c.NCHPApp.public_ip = '0.0.0.0'
c.NCHPApp.public_port = 8000
c.NCHPApp.api_ip = '127.0.0.1'
c.NCHPApp.api_port = 8001
c.NCHPApp.default_target = 'http://127.0.0.1:8081'
