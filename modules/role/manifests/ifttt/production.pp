# == Class role::ifttt::staging
# This is the staging specific ifttt role
class role::ifttt::staging {
    include ::ifttt::base

    class { '::ifttt::web':
        workers => 4,
    }
}
