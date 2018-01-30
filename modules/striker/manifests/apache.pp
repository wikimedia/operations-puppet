# = Class: striker::apache
#
# Serve static assets for Striker and route other requests to the Django
# backend.
#
# == Parameters:
# [*server_name*]
#   vhost name
# [*docroot*]
#   Document root for vhost
# [*servers*]
#   List of URLs of backend servers to forward non-static asset requests to
# [*port*]
#   Port for apache to listen on. Default 80.
#
class striker::apache(
    $server_name,
    $docroot,
    $servers,
    $port = 80,
){

    class { '::httpd':
        modules => ['expires', 'headers', 'lbmethod_byrequests', 'proxy', 'proxy_balancer', 'proxy_http'],
    }

    httpd::site { 'striker':
        content => template('striker/apache.conf.erb'),
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
