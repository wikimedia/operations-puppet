# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker {
    apt::repository { 'thirdparty-ci':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/ci',
    }
    package { 'docker-ce':
        ensure  => present,
        require => [
          Apt::Repository['thirdparty-ci'],
          Exec['apt-get update']
        ],
    }
    # Ensure jenkins-deploy membership in the docker group
    exec { 'jenkins-deploy docker membership':
        unless  => '/usr/bin/id -Gn jenkins-deploy | /bin/grep -qw "docker"',
        command => '/usr/sbin/usermod -aG docker jenkins-deploy',
        require => [
            Package['docker-ce'],
        ],
    }
}
