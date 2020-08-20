# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker(
    $jenkins_agent_username = lookup('jenkins_agent_username'),
    $settings = lookup('profile::ci::docker::settings'),
) {
    # Let us elevate permissions to the user running a containerized process
    require_package('acl')

    if os_version('debian < buster') {
        apt::repository { 'thirdparty-ci':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/ci',
        }
    }

    class { '::docker::configuration':
        settings => $settings,
    }

    # TODO: Drop the entire version-specific pinning once jessie/stretch is gone
    $docker_version = $::lsbdistcodename ? {
        'jessie'  => '18.06.2~ce~3-0~debian',
        'stretch' => '5:19.03.5~3-0~debian-stretch',
        'buster'  => '18.09.1+dfsg1-7.1+deb10u2',
    }

    $docker_package = $::lsbdistcodename ? {
        'jessie'  => 'docker-ce',
        'stretch' => 'docker-ce',
        'buster'  => 'docker.io',
    }

    class { '::docker':
        package_name => $docker_package,
        version      => $docker_version,
    }

    if $::realm == 'labs' {
        # ensure jenkins-deploy membership in the docker group
        exec { 'jenkins user docker membership':
            unless  => "/usr/bin/id -Gn '${jenkins_agent_username}' | /bin/grep -qw 'docker'",
            command => "/usr/sbin/usermod -aG docker '${jenkins_agent_username}'",
            require => [
                Package['docker-ce'],
            ],
        }
    }

    # Ship the entire docker iptables configuration via ferm
    # This is here to make sure docker and ferm play nice together.
    ferm::conf { 'docker-ferm':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/profile/ci/docker-ferm',
    }
}
