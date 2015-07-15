# vim:sw=4 ts=4 sts=4 et:

# == Class: role::sentry
#
# Provisions Sentry
#
class role::sentry {
    class { '::sentry': }
}
