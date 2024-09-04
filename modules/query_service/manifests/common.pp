# SPDX-License-Identifier: Apache-2.0
# = Class: query_service::common
# Note: setup environment for query service.
# Dump data must be loaded manually.
#
# == Parameters:
# - $username: Username owning the service.
# - $endpoint: External endpoint name.
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored.
# - $log_dir: Directory where the logs go.
# - $categories_endpoint: Endpoint which category scripts will be using.
class query_service::common(
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

    class {'::query_service::deploy::scap':
      deploy_user => $deploy_user,
      username    => $username,
      package_dir => $package_dir,
      deploy_name => $deploy_name,
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

    # Only a single query_service can be installed per host, provide a common name
    # to access logs without having to know which one we are on.
    if ($log_dir != '/var/log/query_service') {
        file { '/var/log/query_service':
            ensure => link,
            target => $log_dir,
        }
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

    $config_dir_group = $deploy_user

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

    # GC logs rotation is done by the JVM, but on JVM restart, the logs left by
    # the previous instance are left alone. This systemd timer job takes care of
    # cleaning up GC logs older than 30 days.
    $gc_log_subpath = $deploy_name ? {
        'wcqs'   => 'query_service',
        default  => $deploy_name,
    }
    $gc_log_cleanup_cmd = "/usr/bin/find /var/log/${gc_log_subpath}/ -name '${deploy_name}-*_jvm_gc.*.log*' -mtime +30 -delete"

    systemd::timer::job { 'query-service-gc-log-cleanup':
        ensure      => present,
        description => 'Regular job for cleaning up query service GC logs older than 30 days',
        user        => 'root',
        command     => $gc_log_cleanup_cmd,
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 2:12:00'},
    }

}
