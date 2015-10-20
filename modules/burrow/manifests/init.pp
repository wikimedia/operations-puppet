class burrow (
    $ensure = 'present',
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

    $config_dir = '/etc/burrow/config'
    $log_dir = '/var/log/burrow'

    file { "${config_dir}/burrow.cfg":
        ensure  => $ensure,
        content => template('burrow/burrow.cfg.erb'),
    }

    file { "${config_dir}/logging.cfg":
        ensure => $ensure,
        source  => 'puppet:///modules/burrow/logging.cfg',
    }

    file { "${config_dir}/default-email.tmpl":
        ensure => $ensure,
        source  => 'puppet:///modules/burrow/default-email.tmpl',
    }

    service { "burrow":
        ensure => $ensure,
        enable => true,
    }
}
