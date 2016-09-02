# = Define: external_proxy::instance
#
# Provision an nginx vhost that acts as a reverse proxy to the given URL.
#
# == Parameters:
# [*proxied*]
#   URL of proxied server. Example 'https://localhost:8443'
# [*acls*]
#   Ordered list of nginx access control directives to apply.
#   See https://nginx.org/en/docs/http/ngx_http_access_module.
# [*port*]
#   Port that nginx should listen on. Default: 80.
# [*default*]
#   Should this vhost be the default for Host values that are otherwise
#   unhandled? Default: false.
#
define external_proxy::instance (
    $proxied,
    $acls,
    $port    = 80,
    $default = false,
){
    include ::nginx
    nginx::site { $vhost:
        content => template('external_proxy/instance.conf.erb'),
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
