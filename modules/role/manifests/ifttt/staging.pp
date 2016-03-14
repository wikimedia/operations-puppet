# == Class role::ifttt::staging
# This is the staging specific ifttt role
class role::ifttt::staging {
    include ::ifttt::base

    class { '::ifttt::web':
        workers_per_core => 1,
    }
}
