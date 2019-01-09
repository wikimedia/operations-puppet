# === Class: wdqs::blazegraph
# Note: This class installs and start the blazegraph service for WDQS
#
# == Parameters:
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored
# - $logstash_host: hostname where to send logs
# - $endpoint: External endpoint name
# - $logstash_json_port: port on which to send logs in json format
# - $log_dir: Directory where the logs go
# - $heap_size: heapsize for blazegraph
# - $username: Username owning the service
# - $deploy_user: username of deploy user
# - $use_deployed_config: Whether we should use config in deployed repo or our own
# - $options: options for Blazegraph startup script
# - $extra_jvm_opts: Extra JVM configs for wdqs-blazegraph
class wdqs::blazegraph(
    Stdlib::Unixpath $package_dir,
    Stdlib::Unixpath $data_dir,
    String $logstash_host,
    String $endpoint,
    Wmflib::IpPort $logstash_json_port,
    Stdlib::Unixpath $log_dir,
    String $heap_size,
    String $username,
    Boolean $use_deployed_config,
    Array[String] $options,
    Array[String] $extra_jvm_opts,
) {
    if ($use_deployed_config) {
        $config_file = 'RWStore.properties'
    } else {
        $config_file = '/etc/wdqs/RWStore.properties'
        file { $config_file:
            ensure  => present,
            content => template('wdqs/RWStore.properties.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            before  => Systemd::Unit['wdqs-blazegraph'],
        }
    }

    # Blazegraph tries to log to this file, redirect to log dir
    file { "${package_dir}/rules.log":
        ensure  => link,
        target  => "${log_dir}/rules.log",
        require => [ File[$package_dir], File[$log_dir] ],
        before  => Service['wdqs-blazegraph'],
        tag     => 'in-wdqs-package-dir',
    }

    file { '/etc/default/wdqs-blazegraph':
        ensure  => present,
        content => template('wdqs/blazegraph-default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Systemd::Unit['wdqs-blazegraph'],
    }

    wdqs::logback_config { 'wdqs-blazegraph':
        logstash_host => $logstash_host,
        logstash_port => $logstash_json_port,
        log_dir       => $log_dir,
        pattern       => '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} IP:%X{req.remoteHost} UA:%X{req.userAgent} - %msg%n%rEx{1,QUERY_TIMEOUT,SYNTAX_ERROR}',
        evaluators    => true,
    }

    # Blazegraph service
    systemd::unit { 'wdqs-blazegraph':
        content => template('wdqs/initscripts/wdqs-blazegraph.systemd.erb'),
    }

    service { 'wdqs-blazegraph':
        ensure => 'running',
    }

}