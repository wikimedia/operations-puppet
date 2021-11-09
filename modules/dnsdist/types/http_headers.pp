# == Type: Dnsdist::Http_headers
#
# Custom HTTP headers returned by dnsdist's webserver, such as
# strict-transport-security, etc.

type Dnsdist::Http_headers = Hash[String[1], String[1]]
