# == Class role::ci:slave::labs::docker
#
# Experimental Jenkins slave instance for providing Docker based CI builds.
#
class role::ci::slave::labs::docker {
    requires_realm('labs')

    include role::ci::slave::labs::common
    include ::docker
    include phabricator::arcanist
    include ::zuul

    system::role { 'role::ci::slave::labs::docker':
        description => 'CI Jenkins slave using Docker on labs' }

    class { 'contint::worker_localhost':
        owner => 'jenkins-deploy',
    }

    # Ensure jenkins-deploy membership in the docker group
    exec { 'jenkins-deploy docker membership':
        unless  => "/usr/bin/id -Gn jenkins-deploy | /bin/grep -q '\bdocker\b'",
        command => '/usr/sbin/usermod -aG docker jenkins-deploy',
    }
}
