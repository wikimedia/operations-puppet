# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#

class profile::ci::docker {
    include ::docker

    # Ensure jenkins-deploy membership in the docker group
    exec { 'jenkins-deploy docker membership':
        unless  => '/usr/bin/id -Gn jenkins-deploy | /bin/grep -qw "docker"',
        command => '/usr/sbin/usermod -aG docker jenkins-deploy',
        require => [
            Class['::docker'],
        ],
    }
}
