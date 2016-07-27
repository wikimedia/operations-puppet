# == Class: role::striker::web
#
# Striker is a Django application for managing data related to Tool Labs
# tools.
#
class role::striker::web {
    include ::memcached
    include ::striker::nginx
    include ::striker::uwsgi
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
