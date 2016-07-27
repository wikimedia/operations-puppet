# = Class: striker::nginx
#
# Serve static assets for Striker and route other requests to the Django
# backend.
#
# == Parameters:
# [*server_name*]
#   Nginx vhost name
# [*docroot*]
#   Document root for nginx vhost
# [*servers*]
#   Array of 'host:port' values pointing to backend striker::uwsgi servers
# [*port*]
#   Port for nginx to listen on. Default 80.
#
class striker::nginx(
    $server_name,
    $docroot,
    $servers,
    $port = 80,
){
    class { '::nginx':
        variant => 'light',
    }
    nginx::site { 'striker':
        content => template('striker/nginx.conf.erb'),
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
