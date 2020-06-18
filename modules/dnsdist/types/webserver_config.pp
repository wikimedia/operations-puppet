# == Type: Dnsdist::Webserver_config
#
# Configuration for dnsdist's webserver.
#
#  [*host/port*]
#    [host/port] address to listen on. required.
#
#  [*password*]
#    [string] password to access the server. required.
#
#  [*api_key*]
#    [string] API access key (/metrics). required.

type Dnsdist::Webserver_config = Struct[{
    host     => Stdlib::Host,
    port     => Stdlib::Port,
    password => String[1],
    api_key  => String[1],
}]
