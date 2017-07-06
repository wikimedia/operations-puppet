# == Class: role::striker::web
#
# Striker is a Django application for managing data related to Tool Labs
# tools.
#
# filtertags: labs-project-striker
class role::striker::web {
    include ::memcached
    include ::striker::apache
    include ::striker::uwsgi
    require ::passwords::striker

    ferm::service { 'striker':
        proto => 'tcp',
        port  => '8081',
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
