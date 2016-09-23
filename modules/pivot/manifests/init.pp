# == Class: imply_pivot
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
# TODO
#

class pivot(
    $port            = 9090,
    $druid_broker    = undef,
    $deployment_user = 'analytics_deploy',
    $scap_repo       = 'analytics/pivot/deploy',
    $contact_group   = 'admins',
) {

    requires_os('debian >= jessie')
    require_package('nodejs', 'nodejs-legacy', 'firejail')

    $scap_deployment_base_dir = '/srv/deployment'
    $pivot_deployment_dir = "${scap_deployment_base_dir}/${scap_repo}"

    monitoring::service { 'pivot':
        description   => 'pivot',
        check_command => "check_tcp!${port}",
        contact_group => $contact_group
    }

    scap::target { 'analytics/pivot/deploy':
        deploy_user  => $deployment_user,
        service_name => 'pivot',
        before       => Base::Service_unit['pivot'],
    }

    group { 'pivot':
        ensure => present,
        system => true,
        before => User['pivot'],
    }

    user { 'pivot':
        gid    => 'pivot',
        shell  => '/bin/bash',
        system => true,
        before => Base::Service_unit['pivot'],
    }

    file { '/var/log/pivot':
        ensure => directory,
        owner  => 'pivot',
        group  => 'root',
        mode   => '0755',
        after  => User['pivot'],
    }

    file { '/etc/firejail/pivot.profile':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/pivot/pivot.profile.firejail',
        before => Base::Service_Unit['pivot'],
    }

    logrotate::conf { 'pivot':
        ensure => present,
        source => 'puppet:///modules/pivot/pivot.logrotate.conf',
    }

    systemd::syslog { 'pivot':
        readable_by => 'all',
        base_dir    => '/var/log/pivot',
        group       => 'root',
        before      => Base::Service_unit['pivot'],
    }

    base::service_unit { 'pivot':
        ensure  => present,
        systemd => true,
    }
}
