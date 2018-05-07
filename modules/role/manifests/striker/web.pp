# == Class: role::striker::web
#
# Striker is a Django application for managing data related to Tool Labs
# tools.
#
# filtertags: labs-project-striker
class role::striker::web {

    if os_version('debian >= stretch') {
        require_package('libapache2-mod-wsgi-py3')
        class { '::httpd':
            modules => ['alias', 'ssl', 'rewrite', 'headers', 'wsgi',
                        'proxy', 'expires', 'proxy_http', 'proxy_balancer',
                        'lbmethod_byrequests'],
        }
    }

    include ::memcached
    include ::profile::prometheus::memcached_exporter
    include ::striker::apache
    include ::striker::uwsgi
    require ::passwords::striker
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
