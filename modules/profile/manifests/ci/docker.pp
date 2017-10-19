# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker(
    $jenkins_agent_username = hiera('jenkins_agent_username'),
) {
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
    exec { 'jenkins user docker membership':
        unless  => "/usr/bin/id -Gn '${jenkins_agent_username}' | /bin/grep -qw 'docker'",
        command => "/usr/sbin/usermod -aG docker '${jenkins_agent_username}'",
        require => [
            Package['docker-ce'],
        ],
    }
}
