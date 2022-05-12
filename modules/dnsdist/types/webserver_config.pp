# @summary configuration for dnsdist's webserver.
#
# @param host/port
#    address to listen on. required.
#
# @param password
#    password to access the server. required.
#
# @param api_key
#    API access key (/metrics). required.
#
# @param acl
#    list of IP addresses allowed to access the webserver. required.

type Dnsdist::Webserver_config = Struct[{
    host     => Stdlib::Host,
    port     => Stdlib::Port,
    password => String[1],
    api_key  => String[1],
    acl      => Array[Stdlib::IP::Address],
}]
