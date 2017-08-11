# == Class: pivot
#
# This class installs and configures the Imply Pivot nodejs application.
#
# Context up to September 2016:
# There is a current dispute between Imply and Metamarkets about a possible
# copyright infringement related to Imply's pivot UI.
# The Analytics team set a while back a goal to provide a Pivot UI
# to their users with the assumption that all the code
# used/deployed was open souce and freely available. If this assumption will
# change in the future, for example after a legal sentence, the Analytics team
# will take the necessary actions.
# For any question please reach out to the Analytics team:
# https://www.mediawiki.org/wiki/Analytics#Contact
#
# Bug: T138262
#
# === Parameters
#
# [*port*]
#   The port used by Pivot to accept HTTP connections.
#   Default: 9090
#
# [*druid_broker*]
#   The fully qualified domain name (like druid1001.eqiad.wmnet)
#   of the Druid Broker that the Pivot UI will contact.
#   Default: undef
#
# [*query_timeout*]
#   The timeout to set on the Druid queries in ms.
#   Default: 40000
#
# [*source_refresh_ms*]
#   How often should Druid sources be reloaded in ms.
#   Default: 15000
#
# [*schema_refresh_ms*]
#   How often should Druid source schema be reloaded in ms.
#   Default: 120000
#
# [*deployment_user*]
#   Scap deployment user.
#   Default: 'analytics_deploy'
#
# [*scap_repo*]
#   Scap repository.
#   Default: 'analytics/pivot/deploy'
#
# [*contact_group*]
#   Contact group for alerts.
#   Default: 'admins'
#
class pivot(
    $port              = 9090,
    $druid_broker      = undef,
    $query_timeout     = 40000,
    $source_refresh_ms = 15000,
    $schema_refresh_ms = 120000,
    $deployment_user   = 'analytics_deploy',
    $scap_repo         = 'analytics/pivot/deploy',
    $contact_group     = 'admins',
) {

    requires_os('debian >= jessie')
    require_package('nodejs', 'firejail')

    $scap_deployment_base_dir = '/srv/deployment'
    $pivot_deployment_dir = "${scap_deployment_base_dir}/${scap_repo}"

    scap::target { 'analytics/pivot/deploy':
        deploy_user  => $deployment_user,
        service_name => 'pivot',
    }

    group { 'pivot':
        ensure => present,
        system => true,
    }

    user { 'pivot':
        gid     => 'pivot',
        shell   => '/bin/bash',
        system  => true,
        require => Group['pivot'],
    }

    file { '/etc/firejail/pivot.profile':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/pivot/pivot.profile.firejail',
    }

    file { '/etc/pivot':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/pivot/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('pivot/config.yaml.erb'),
        require => File['/etc/pivot'],
    }

    systemd::syslog { 'pivot':
        readable_by => 'all',
        base_dir    => '/var/log',
        group       => 'root',
    }

    systemd::service { 'pivot':
        ensure  => present,
        systemd => systemd_template('pivot'),
        restart => true,
        require => [
            Scap::Target['analytics/pivot/deploy'],
            File['/etc/firejail/pivot.profile'],
            File['/etc/pivot/config.yaml'],
            User['pivot'],
            Systemd::Syslog['pivot'],
        ],
    }

    monitoring::service { 'pivot':
        description   => 'pivot',
        check_command => "check_tcp!${port}",
        contact_group => $contact_group,
        require       => Systemd::Service['pivot'],
    }
}
