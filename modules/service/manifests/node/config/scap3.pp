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
    $discovery       = undef,
    $confd_template  = undef,
    $max_splay       = 120,
){
    require ::service::configuration
    # the local log file name
    $local_logdir = "${service::configuration::log_dir}/${title}"
    $local_logfile = "${local_logdir}/main.log"
    # We need to ensure that the full config gets deployed when we change the
    # puppet controlled part. If auto_refresh is true, this will also restart
    # the service.
    file { "/usr/local/bin/apply-config-${title}":
        ensure  => present,
        content => template('service/node/apply-config.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        before  => Exec["${title} config deploy"],
    }

    if $discovery {
        confd::file { "/etc/${title}/config-vars.yaml":
            ensure     => present,
            watch_keys => "/discovery/${discovery}",
            reload     => "nohup /usr/local/apply-config-${title} &"
        }
    } else {
        file { "/etc/${title}/config-vars.yaml":
            ensure  => present,
            content => template('service/node/config-vars.yaml.erb'),
            owner   => $deployment_user,
            group   => $deployment_user,
            mode    => '0444',
            tag     => "${title}::config",
        }
        exec { "${title} config deploy":
            command     => "/usr/local/bin/apply-config-${title}",
            user        => $deployment_user,
            group       => $deployment_user,
            refreshonly => true,
            subscribe   => File["/etc/${title}/config-vars.yaml"],
        }
    }
}
