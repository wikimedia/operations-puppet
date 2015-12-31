# proxymanager API

For URL proxy forwards, for example in the Tools project, dynamicproxy
exposes a RESTful API at port 8081.

The list of all active forwards is managed at `/v1/proxy-forwards`.
This endpoint only supports `GET` requests; its list is structured as:

    ["admin","test2"]

Individual forwards are managed at `/v1/proxy-forwards/$prefix`.  This
endpoint unconditionally supports `GET` requests that return
structures like:

    {".*":"http:\/\/toolsbeta-webgrid-lighttpd-1406.toolsbeta.eqiad.wmflabs:51856"}

for active forwards.  `PUT` and `DELETE` cause the requester to be
authenticated by ident (RFC 1413).  Only if the user name of the
requester is equal to the name of the forward, prefixed with the name
of the project and a dot ("."), does the creation, update or deletion
of the forward succeed.
