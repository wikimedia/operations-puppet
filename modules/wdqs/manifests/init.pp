# = Class: wdqs
# Note: this does not run the service, just installs it
# In order to run it, dump data must be loaded, which is
# for now a manual process.
#
# == Parameters:
# - $logstash_host: hostname where to send logs
# - $logstash_json_port: port on which to send logs in json format
# - $deploy_mode: whether scap deployment is being used or git for autodeployment
# - $username: Username owning the service
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored
# - $log_dir: Directory where the logs go
# - $endpoint: External endpoint name
# - $blazegraph_options: options for Blazegraph startup script
# - $blazegraph_heap_size: heapsize for blazegraph
# - $blazegraph_config_file: Blazegraph properties config file
class wdqs(
    String $logstash_host,
    Wmflib::IpPort $logstash_json_port = 11514,
    Wdqs::DeployMode $deploy_mode = 'scap3',
    String $username = 'blazegraph',
    String $package_dir = '/srv/deployment/wdqs/wdqs',
    String $data_dir = '/srv/wdqs',
    String $log_dir = '/var/log/wdqs',
    String $endpoint = '',
    Array[String] $blazegraph_options = [],
    String $blazegraph_heap_size = '32g',
    String $blazegraph_config_file = 'RWStore.properties',
    Array[String] $extra_jvm_opts = [],
) {

    $deploy_user = 'deploy-service'
    $data_file = "${data_dir}/wikidata.jnl"

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

    class { 'wdqs::service':
        deploy_user        => $deploy_user,
        deploy_mode        => $deploy_mode,
        package_dir        => $package_dir,
        username           => $username,
        config_file        => $blazegraph_config_file,
        logstash_host      => $logstash_host,
        logstash_json_port => $logstash_json_port,
    }

    file { $log_dir:
        ensure => directory,
        owner  => $username,
        group  => 'root',
        mode   => '0775',
    }

    # Blazegraph tries to log to this file, redirect to log dir
    file { "${package_dir}/rules.log":
        ensure  => link,
        target  => "${log_dir}/rules.log",
        require => [ File[$package_dir], File[$log_dir] ],
        before  => Service['wdqs-blazegraph'],
        tag     => 'in-wdqs-package-dir',
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

    # This is a rather ugly hack to ensure that permissions of $data_file are
    # managed, but that the file is not created by puppet. If that file does
    # not exist, puppet will raise an error and skip the File[$data_file]
    # resource (and only that resource). It means that puppet will be in error
    # until data import is started, but that's a reasonable behaviour.
    exec { "${data_file} exists":
        command => '/bin/true',
        onlyif  => "/usr/bin/test -e ${data_file}",
    }
    file { $data_file:
        ensure  => file,
        owner   => $username,
        group   => $username,
        mode    => '0664',
        require => Exec["${data_file} exists"],
        tag     => 'in-wdqs-data-dir',
    }

    $config_dir_group = $deploy_mode ? {
        'scap3'    => $deploy_user,
        default => 'root',
    }

    file { '/etc/wdqs':
        ensure => directory,
        owner  => 'root',
        group  => $config_dir_group,
        mode   => '0775',
    }

    file { '/etc/default/wdqs-blazegraph':
        ensure  => present,
        content => template('wdqs/blazegraph-default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Systemd::Unit['wdqs-blazegraph'],
    }

    file { '/etc/wdqs/vars.yaml':
        ensure  => present,
        content => template('wdqs/vars.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    wdqs::logback_config { 'wdqs-blazegraph':
        logstash_host => $logstash_host,
        logstash_port => $logstash_json_port,
        pattern       => '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} IP:%X{req.remoteHost} UA:%X{req.userAgent} - %msg%n%rEx{1,QUERY_TIMEOUT,SYNTAX_ERROR}',
        evaluators    => true,
    }

    # GC logs rotation is done by the JVM, but on JVM restart, the logs left by
    # the previous instance are left alone. This cron takes care of cleaning up
    # GC logs older than 30 days.
    cron { 'wdqs-gc-log-cleanup':
      ensure  => present,
      minute  => 12,
      hour    => 2,
      command => "find /var/log/wdqs -name 'wdqs-*_jvm_gc.*.log*' -mtime +30 -delete",
    }
}
