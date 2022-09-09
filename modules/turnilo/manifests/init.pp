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
    Array[Turnilo::Druid_cluster]     $druid_clusters,
    Stdlib::Port                      $port             = 9091,
    String                            $deployment_user  = 'analytics_deploy',
    String                            $scap_repo        = 'analytics/turnilo/deploy',
    Hash[Stdlib::IP::Address, String] $export_names_map = {},
) {

    ensure_packages(['nodejs', 'firejail'])

    $scap_deployment_base_dir = '/srv/deployment'
    $turnilo_deployment_dir = "${scap_deployment_base_dir}/${scap_repo}"

    scap::target { 'analytics/turnilo/deploy':
        deploy_user  => $deployment_user,
        service_name => 'turnilo',
    }

    systemd::sysuser { 'turnilo':
        shell    => '/bin/bash',
    }

    file { '/etc/firejail/turnilo.profile':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/turnilo/turnilo.profile.firejail',
        require => Package['firejail'],
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
        force_stop  => true,
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
