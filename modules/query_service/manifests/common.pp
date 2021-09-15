# = Class: query_service::common
# Note: setup environment for query service.
# Dump data must be loaded manually.
#
# == Parameters:
# - $deploy_mode: whether scap deployment is being used or git for autodeployment.
# - $username: Username owning the service.
# - $endpoint: External endpoint name.
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored.
# - $log_dir: Directory where the logs go.
# - $categories_endpoint: Endpoint which category scripts will be using.
class query_service::common(
    Query_service::DeployMode $deploy_mode,
    String $username,
    String $deploy_user,
    String $endpoint,
    String $deploy_name,
    Stdlib::Unixpath $package_dir,
    Stdlib::Unixpath $data_dir,
    Stdlib::Unixpath $log_dir,
    Stdlib::Httpurl $categories_endpoint,
) {
    include ::query_service::packages

    $autodeploy_log_dir = "/var/log/${deploy_name}-autodeploy"

    case $deploy_mode {

        'scap3': {
            class {'::query_service::deploy::scap':
                deploy_user => $deploy_user,
                username    => $username,
                package_dir => $package_dir,
                deploy_name => $deploy_name,
            }
        }

        'manual': {
            class {'::query_service::deploy::manual':
                deploy_user => $deploy_user,
                package_dir => $package_dir,
                deploy_name => $deploy_name,
            }
        }

        'autodeploy': {
            class { '::query_service::deploy::autodeploy':
                deploy_user        => $deploy_user,
                package_dir        => $package_dir,
                autodeploy_log_dir => $autodeploy_log_dir,
                deploy_name        => $deploy_name,
            }
        }

        default: { }
    }

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
        home       => $data_dir,
        managehome => no,
    }

    file { $log_dir:
        ensure => directory,
        owner  => $username,
        group  => 'root',
        mode   => '0775',
    }

    # If we have data in separate dir, make link in package dir
    if $data_dir != $package_dir {
        file { $data_dir:
            ensure => directory,
            owner  => $username,
            group  => 'wikidev',
            mode   => '0775',
        }
    }

    # putting dumps into the data dir since they're large
    file { "${data_dir}/dumps":
        ensure => directory,
        owner  => $username,
        group  => 'wikidev',
        mode   => '0775',
        tag    => 'in-wdqs-data-dir',
    }

    $config_dir_group = $deploy_mode ? {
        'scap3'    => $deploy_user,
        default => 'root',
    }

    file { "/etc/${deploy_name}":
        ensure => directory,
        owner  => 'root',
        group  => $config_dir_group,
        mode   => '0775',
    }

    file { '/etc/query_service':
        ensure => link,
        target => "/etc/${deploy_name}"
    }

    file { "/etc/${deploy_name}/vars.yaml":
        ensure  => present,
        content => template('query_service/vars.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    # These variables are read by the scap promotion process for wdqs/wdqs, and thus must be
    # made avaliable prior to installing the package.
    File["/etc/${deploy_name}/vars.yaml"] -> Package['wdqs/wdqs']

    # GC logs rotation is done by the JVM, but on JVM restart, the logs left by
    # the previous instance are left alone. This systemd timer job takes care of
    # cleaning up GC logs older than 30 days.
    systemd::timer::job { 'query-service-gc-log-cleanup':
        ensure      => present,
        description => 'Regular jobs for cleaning up GC logs older than 30 days',
        user        => 'root',
        command     => "/usr/bin/find /var/log/${deploy_name} -name '${deploy_name}-*_jvm_gc.*.log*' -mtime +30 -delete",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 2:12:00'},
    }

}
