# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker(
    $jenkins_agent_username = lookup('jenkins_agent_username'),
    $settings = lookup('profile::ci::docker::settings'),
) {
    include profile::docker::prune

    # Let us elevate permissions to the user running a containerized process
    ensure_packages('acl')

    if debian::codename::lt('bullseye') {
        apt::repository { 'thirdparty-ci':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/ci',
        }
    }

    class { 'docker::configuration':
        settings => $settings,
    }

    # TODO: Drop the entire version-specific pinning once buster is gone
    $docker_version = $::lsbdistcodename ? {
        'buster'  => '5:20.10.12~3-0~debian-buster',
        # Docker version is ignored starting with Bullseye
        default   => 'present',
    }

    $docker_package = $::lsbdistcodename ? {
        'buster'   => 'docker-ce',
        'bullseye' => 'docker.io',
    }

    ensure_packages(
        $docker_package,
        {
            'ensure'  => $docker_version,
            'require' => Class['docker::configuration'],
        },
    )

    # Upstream docker debian package does not enable the service and it thus
    # does not start on reboot T313119
    service { 'docker':
        enable => true,
    }

    file { '/usr/local/bin/docker-credential-environment':
        source => 'puppet:///modules/docker/docker-credential-environment.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if $::realm == 'labs' {
        # ensure jenkins-deploy membership in the docker group
        exec { 'jenkins user docker membership':
            unless  => "/usr/bin/id -Gn '${jenkins_agent_username}' | /bin/grep -qw 'docker'",
            command => "/usr/sbin/usermod -aG docker '${jenkins_agent_username}'",
            require => [
                Package[ $docker_package ],
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
