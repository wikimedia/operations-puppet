# == Class role::ci:slave::labs::docker
#
# Experimental Jenkins slave instance for providing Docker based CI builds.
#
class role::ci::slave::labs::docker {
    requires_realm('labs')

    include role::ci::slave::labs::common
    include ::docker

    system::role { 'role::ci::slave::labs::docker':
        description => 'CI Jenkins slave using Docker on labs' }

    class { 'contint::worker_localhost':
        owner => 'jenkins-deploy',
    }
}
