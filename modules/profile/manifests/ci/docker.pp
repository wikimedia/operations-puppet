# SPDX-License-Identifier: Apache-2.0
# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker(
    $jenkins_agent_username = lookup('jenkins_agent_username'),
    $settings = lookup('profile::ci::docker::settings'),
    $docker_version = lookup('profile::ci::docker::docker_version'),
) {
    include profile::docker::prune
    include profile::ci::thirdparty_apt

    # Let us elevate permissions to the user running a containerized process
    ensure_packages('acl')

    class { 'docker::configuration':
        settings => $settings,
    }

    profile::auto_restarts::service { 'docker':
        ensure => absent,
    }

    profile::auto_restarts::service { 'containerd':
        ensure => absent,
    }

    # Upstream package versions are always suffixed with "-codename"
    $full_docker_version = "${docker_version}-${::lsbdistcodename}"

    ensure_packages(
        'docker-ce',
        {
            'ensure'  => $full_docker_version,
            'require' => [
                Class['docker::configuration'],
                Class['profile::ci::thirdparty_apt'],
            ],
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
