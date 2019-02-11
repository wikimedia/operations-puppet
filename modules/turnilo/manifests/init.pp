# == Class: turnilo
#
# This class installs and configures the Allegro Turnilo nodejs application.
#
# Turnilo is an open source replacement for Imply Pivot.
#
# === Parameters
#
# [*port*]
#   The port used by Turnilo to accept HTTP connections.
#   Default: 9091
#
# [*druid_clusters*]
#   Array of hashes of druid cluster config.  Each hash must
#   contain at least 'name' and 'host' with the druid broker hostname:port.
#
# [*deployment_user*]
#   Scap deployment user.
#   Default: 'analytics_deploy'
#
# [*scap_repo*]
#   Scap repository.
#   Default: 'analytics/turnilo/deploy'
#
class turnilo(
    $druid_clusters,
    $port              = 9091,
    $deployment_user   = 'analytics_deploy',
    $scap_repo         = 'analytics/turnilo/deploy',
) {

    # Nodejs 10 upgrade - T210705
    if os_version('debian == stretch') {
        apt::repository { 'wikimedia-node10':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'stretch-wikimedia',
            components => 'component/node10',
            before     => Package['nodejs'],
        }
    }

    package { ['nodejs', 'firejail']:
        ensure => 'present'
    }

    $scap_deployment_base_dir = '/srv/deployment'
    $turnilo_deployment_dir = "${scap_deployment_base_dir}/${scap_repo}"

    scap::target { 'analytics/turnilo/deploy':
        deploy_user  => $deployment_user,
        service_name => 'turnilo',
    }

    group { 'turnilo':
        ensure => present,
        system => true,
    }

    user { 'turnilo':
        gid     => 'turnilo',
        shell   => '/bin/bash',
        system  => true,
        require => Group['turnilo'],
    }

    file { '/etc/firejail/turnilo.profile':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/turnilo/turnilo.profile.firejail',
    }

    file { '/etc/turnilo':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/turnilo/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('turnilo/config.yaml.erb'),
        require => File['/etc/turnilo'],
    }

    systemd::syslog { 'turnilo':
        readable_by => 'all',
        base_dir    => '/var/log',
        group       => 'root',
    }

    systemd::service { 'turnilo':
        ensure  => present,
        content => systemd_template('turnilo'),
        restart => true,
        require => [
            Scap::Target['analytics/turnilo/deploy'],
            File['/etc/firejail/turnilo.profile'],
            File['/etc/turnilo/config.yaml'],
            User['turnilo'],
            Systemd::Syslog['turnilo'],
        ],
    }
}
