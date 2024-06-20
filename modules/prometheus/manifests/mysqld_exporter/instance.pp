# == Define: prometheus::mysqld_exporter::instance
#
# Prometheus exporter for MySQL server metrics. The exporter is most effective
# when ran alongside the MySQL server to be monitored, connecting via a local
# UNIX socket is supported.
#
# = Parameters
#
# [*client_socket*]
#   The socket to connect to.
#
# [*client_user*]
#   MySQL user
#
# [*client_password*]
#   MySQL password
#
# [*listen_address*]
#   ip/host and port, colon separated, where the prometheus exporter will listen for
#   http metrics requests. Host can be omitted.

define prometheus::mysqld_exporter::instance (
    Stdlib::Unixpath $client_socket   = '/run/mysqld/mysqld.sock',
    String           $client_user     = 'prometheus',
    String           $client_password = 'This is a fake passsword, but cannot be empty due to Debian #953040',
    String           $listen_address  = ':9104',
) {
    # TODO: split listen address params
    # Stdlib::IP:Address $listen_ip
    # Stdlib::Port $listen_Port
    # $listen_address = "${listen_ip}:${listen_port}"
    include prometheus::mysqld_exporter::common

    $my_cnf = "/var/lib/prometheus/.my.${title}.cnf"
    $service = "prometheus-mysqld-exporter@${title}"
    $common_options = [
        "web.listen-address \"${listen_address}\"",
        "config.my-cnf \"${my_cnf}\"",
        'collect.global_status',
        'collect.global_variables',
        'collect.info_schema.processlist',
        'collect.slave_status',
        'collect.heartbeat',
        'collect.heartbeat.utc',
    ]

    $option_switch = '--'
    $version_specific_options = ['no-collect.info_schema.tables']

    #We only want to restart if the service is running
    #(which it won't be if the relevant mariadb isn't)
    exec { "systemctl try-restart ${service}":
        refreshonly => true,
        path        => '/usr/bin',
    }

    $options_str = ($common_options + $version_specific_options).reduce('') |$memo, $value| {
        "${memo} ${option_switch}${value}"
    }.strip

    file { "/etc/default/prometheus-mysqld-exporter@${title}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS='${options_str}'",
        notify  => Exec["systemctl try-restart ${service}"],
    }

    # a separate database config (.my.<instance_name>cnf) for each instance monitored
    # change the systemd unit if the patch changes here, as it depends on it
    file { $my_cnf:
        ensure  => present,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('prometheus/mysqld_exporter.cnf.erb'),
        notify  => Exec["systemctl try-restart ${service}"],
    }

    profile::auto_restarts::service { $service: }
}
