# === define service::node::config::scap3
#
# Used to deploy a configuration for a service that uses service::node.
#
# == Parameters
#
# Most parameters have the same meaning as in service::node, to the documentation of which you
# should refer for those.
#
define service::node::config::scap3 (
    $port,
    $no_workers      = 'ncpu',
    $heap_limit      = 300,
    $heartbeat_to    = 7500,
    $repo            = "${title}/deploy",
    $starter_module  = './src/app.js',
    $entrypoint      = '',
    $logging_name    = $title,
    $statsd_prefix   = $title,
    $auto_refresh    = true,
    $deployment_user = 'deploy-service',
    $deployment_vars = {},
){
    require ::service::configuration
    # the local log file name
    $local_logdir = "${service::configuration::log_dir}/${title}"
    $local_logfile = "${local_logdir}/main.log"
    # file mode for config-vars.yaml
    $mode = $deployment_user ? {
        'root'  => '0444',
        default => '0440',
    }
    # We need to ensure that the full config gets deployed when we change the
    # puppet controlled part. If auto_refresh is true, this will also restart
    # the service.
    file { "/usr/local/bin/apply-config-${title}":
        ensure  => present,
        content => template('service/node/apply-config.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    $mwapi_host = pick($::service::configuration::mwapi_host, '')
    $config_base = {
        # general
        num_workers => $no_workers,
        worker_heap_limit_mb => $heap_limit,
        worker_heartbeat_timeout => $heartbeat_to,
        # log-related variables
        log_name => $logging_name,
        logstash_host => pick($::service::configuration::logstash_host, ''),
        logstash_port => pick($::service::configuration::logstash_port, ''),
        log_file => $local_logfile,
        rsyslog_port => pick($::service::configuration::rsyslog_udp_port, ''),
        # metrics
        metrics_name => $statsd_prefix,
        metrics_host => pick($::service::configuration::statsd_host, ''),
        metrics_port => pick($::service::configuration::statsd_port, ''),
        # service
        name => $title,
        module => $starter_module,
        entrypoint => $entrypoint,
        port => $port,
        proxy => pick($::service::configuration::http_proxy, ''),
        mwapi_host => $mwapi_host,
        mwapi_uri => "${mwapi_host}/w/api.php",
        mw_resource_loader_uri => "${mwapi_host}/w/load.php",
        restbase_uri => pick($::service::configuration::restbase_uri, ''),
    }

    $config = merge($config_base, $deployment_vars)

    file { "/etc/${title}/config-vars.yaml":
        ensure    => present,
        content   => $config.to_yaml,
        owner     => $deployment_user,
        group     => $deployment_user,
        mode      => $mode,
        tag       => "${title}::config",
        show_diff => false,
    }
    exec { "${title} config deploy":
        command     => "/usr/local/bin/apply-config-${title}",
        user        => $deployment_user,
        group       => $deployment_user,
        refreshonly => true,
        subscribe   => File["/etc/${title}/config-vars.yaml"],
        require     => File["/usr/local/bin/apply-config-${title}"]
    }
}
