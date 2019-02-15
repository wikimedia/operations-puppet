# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker(
    $jenkins_agent_username = hiera('jenkins_agent_username'),
    $settings = hiera('profile::ci::docker::settings'),
) {
    # Having blubber on all docker nodes will give us a broad pool for all
    # jobs that require similar image building workloads
    require_package('blubber')

    apt::repository { 'thirdparty-ci':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/ci',
    }

    class { '::docker::configuration':
        settings => $settings,
    }
    class { '::docker':
        package_name => 'docker-ce',
        version      => '18.06.2~ce~3-0~debian',
        require      => [
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

    # Ship the entire docker iptables configuration via ferm
    # This is here to make sure docker and ferm play nice together.
    ferm::conf { 'docker-ferm':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/profile/ci/docker-ferm',
    }
}
