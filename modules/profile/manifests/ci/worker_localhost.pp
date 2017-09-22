# == Class profile::ci::worker_localhost
#
class profile::ci::worker_localhost() {
    class { '::contint::worker_localhost':
        owner => 'jenkins-deploy',
    }
}
