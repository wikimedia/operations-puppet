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
# [*backend*]
#   URL for backend server to forward non-static asset requests to
# [*port*]
#   Port for apache to listen on. Default 80.
#
class striker::apache(
    $server_name,
    $docroot,
    $backend,
    $port = 80,
){
    include ::apache
    include ::apache::mod::expires
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http

    apache::site { 'striker':
        content => template('striker/apache.conf.erb'),
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
