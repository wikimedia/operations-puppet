# vim:sw=4 ts=4 sts=4 et:

# == Class: role::sentry
#
# Provisions Sentry
#
class role::sentry {
    include ::sentry
    include ::sentry::ldap

    system::role { 'role::sentry':
        description => 'Sentry server (error aggregation & presentation service)',
    }
}
