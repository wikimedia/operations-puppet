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

    systemd::syslog { 'pivot':
        readable_by => 'all',
        base_dir    => '/var/log',
        group       => 'root',
    }

    base::service_unit { 'pivot':
        ensure  => present,
        systemd => true,
        require => [
            Scap['analytics/pivot/deploy'],
            File['/etc/firejail/pivot.profile'],
            User['pivot'],
            Systemd::Syslog['pivot'],
        ],
    }

    monitoring::service { 'pivot':
        description   => 'pivot',
        check_command => "check_tcp!${port}",
        contact_group => $contact_group,
        require       => Base::Service_unit['pivot'],
    }
}
