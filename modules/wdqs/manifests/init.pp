# = Class: wdqs
# Note: this does not run the service, just installs it
# In order to run it, dump data must be loaded, which is
# for now a manual process.
#
# == Parameters:
# - $username: Username owning the service
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored
# - $log_dir: Directory where the logs go
# - $endpoint: External endpoint name
class wdqs(
    $use_git_deploy = true,
    $username = 'blazegraph',
    $package_dir = '/srv/deployment/wdqs/wdqs',
    $data_dir = '/var/lib/wdqs',
    $log_dir = '/var/log/wdqs',
    $endpoint = '',
) {

    $deploy_user = 'deploy-service'

    group { $username:
        ensure => present,
        system => true,
    }

    user { $username:
        ensure     => present,
        name       => $username,
        comment    => 'Blazegraph user',
        forcelocal => true,
        system     => true,
        #        home       => $package_dir,
        managehome => no,
    }

    include ::wdqs::service

    file { $log_dir:
        ensure  => directory,
        owner   => $username,
        group   => 'wikidev',
        mode    => '0775',
        require => User[$username],
    }

    # Blazegraph tries to log to this file, redirect to log dir
    file { "${package_dir}/rules.log":
        ensure  => link,
        target  => "${log_dir}/rules.log",
        require => [ File[$package_dir], File[$log_dir] ],
        before  => Service['wdqs-blazegraph'],
    }

    # If we have data in separate dir, make link in package dir
    if $data_dir != $package_dir {
        file { $data_dir:
            ensure => directory,
            purge  => false,
            owner  => $username,
            group  => 'wikidev',
            mode   => '0775',
        }
    }

    $config_dir_group = $use_git_deploy ? {
        true    => $deploy_user,
        default => 'root',
    }

    file { '/etc/wdqs':
        ensure => directory,
        owner  => 'root',
        group  => $config_dir_group,
        mode   => '0775',
    }

    file { '/etc/wdqs/vars.yaml':
        ensure  => present,
        content => template('wdqs/vars.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/wdqs/updater-logs.xml':
        ensure  => present,
        content => template('wdqs/updater-logs.xml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    # WDQS Updater service
    include wdqs::updater

    # Deployment
    scap::target { 'wdqs/wdqs':
        service_name => 'wdqs-blazegraph',
        deploy_user  => $deploy_user,
        manage_user  => true,
    }
}
