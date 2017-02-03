# vim:sw=4 ts=4 sts=4 et:

# == Class: role::sentry
#
# Provisions Sentry
#
# filtertags: labs-project-deployment-prep
class role::sentry {
    include ::sentry

    system::role { 'role::sentry':
        description => 'Sentry server (error aggregation & presentation service)',
    }
}
