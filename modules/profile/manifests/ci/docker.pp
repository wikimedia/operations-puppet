# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker(
    $jenkins_agent_username = hiera('jenkins_agent_username'),
    $settings = hiera('profile::ci::docker::settings'),
) {
    apt::repository { 'thirdparty-ci':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/ci',
    }
    class { '::docker':
        package_name => 'docker-ce',
        version      => '17.12.1~ce-0~debian',
        require      => [
            Apt::Repository['thirdparty-ci'],
            Exec['apt-get update']
        ],
    }
    class { '::docker::configuration':
        settings => $settings,
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
