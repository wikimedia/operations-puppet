# === define service::node::config::scap3
#
# Used to deploy a configuration for a service that uses service::node.
#
# == Parameters
#
# Most parameters have the same meaning as in service::node, to the documentation of which you
# should refer for those.
#
# [*discovery*] If set, it will make the config-vars file managed by confd and use discovery
#               based records to change the data in config-vars.yaml and then reload the config.
#
# [*confd_template*] Confd template fragment to include at the end of the config file so that it
#                    can be delegated to confd.
#
# [*max_splay*] For services controlled via confd, enable a splay to delay execution of the service restarts.
#
define service::node::config(
    $port,
    $config          = undef,
    $full_config     = false,
    $no_workers      = 'ncpu',
    $heap_limit      = 300,
    $heartbeat_to    = 7500,
    $logging_name    = $title,
    $local_logging   = true,
    $statsd_prefix   = $title,
    $starter_module  = './src/app.js',
    $entrypoint      = '',
    $use_proxy       = false,
    $auto_refresh    = true,
    $discovery       = undef,
    $confd_template  = undef,
    $max_splay       = 120,
) {
    require ::service::configuration
    # the local log file name
    $local_logdir = "${service::configuration::log_dir}/${title}"
    $local_logfile = "${local_logdir}/main.log"

    # configuration management
    if $full_config {
        unless $config and size($config) > 0 {
            fail('A config needs to be specified when full_config == true!')
        }
        $complete_config = $config
    }
    else {
        # load configuration
        $local_config = $config ? {
            undef   => '{}',
            default => $config
        }
        $complete_config = merge_config(
            template('service/node/config.yaml.erb'),
            $local_config
        )
    }
    file { "/etc/${title}/config.yaml":
        ensure  => present,
        content => $complete_config,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        tag     => "${title}::config",
    }
    if $auto_refresh {
        # if the service should be restarted after a
        # config change, specify the notify/before requirement
        File["/etc/${title}/config.yaml"] ~> Service[$title]
    } else {
        # no restart should happen, just ensure the file is
        # created before the service
        File["/etc/${title}/config.yaml"] -> Service[$title]
    }

}
