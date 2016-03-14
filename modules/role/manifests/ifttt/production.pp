# == Class role::ifttt::production
# This is the production specific ifttt role
class role::ifttt::production {
    include ::ifttt::base

    class { '::ifttt::web':
        workers_per_core => 4,
    }
}
