class burrow (
    $ensure = present,
    $client_id = 'burrow-client',
    $zk_hosts,
    $zk_path,
    $kafka_cluster_name,
    $kafka_hosts,
    $consumer_groups,
    $smtp_server,
    $from_email,
    $to_emails,
)
{
    require_package('golang-burrow')

    $config_dir = 'etc/burrow/config'
    $log_dir = '/var/log/burrow'
    $burrow_config_file = "${config_dir}/burrow.cfg"

    # make sure the log directory exists
    file { $log_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    # make sure the config directory exists
    file { $config_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { $burrow_config_file:
        ensure  => $ensure,
        content => template("${config_dir}/burrow.cfg.erb"),
    }

    file { "${config_dir}/logging.cfg":
        ensure => $ensure,
        source  => 'puppet:///modules/burrow/logging.cfg',
    }

    file { "/etc/burrow/config/default-email.tmpl":
        ensure => $ensure,
        source  => 'puppet:///modules/burrow/default-email.tmpl',
    }

    base::service_unit { 'burrow':
        ensure => $ensure,
        systemd => true,
    }

}