# == Define: prometheus::mysqld_exporter
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
#
# [*arguments*]
#   Additional command line arguments for prometheus-mysqld-exporter.

define prometheus::mysqld_exporter_multiinstance (
    $client_socket = '/run/mysqld/mysqld.sock',
    $client_user = 'prometheus',
    $client_password = '',
    $listen_address = ':13306',
    $arguments = '',
) {
    require_package('prometheus-mysqld-exporter')

    file { "/etc/default/prometheus-mysqld-exporter@${title}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"-web.listen-address=${listen_address} -config.my-cnf=/var/lib/prometheus/my.${title}.cnf ${arguments}\"",
        notify  => Service['prometheus-mysqld-exporter'],
    }

    # a separate database config (.my.<instance_name>cnf) for each instance monitored
    # change the systemd unit if the patch changes here, as it depends on it
    file { "/var/lib/prometheus/my.${title}.cnf":
        ensure  => present,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('prometheus/mysqld_exporter.cnf.erb'),
        require => [
          Package['prometheus-mysqld-exporter'],
          File['/var/lib/prometheus'],
        ],
        notify  => Service["prometheus-mysqld-exporter@${title}"],
    }

    base::service_unit { "prometheus-mysqld-exporter@${title}":
        ensure        => present,
        refresh       => true,
        systemd       => true,
        template_name => 'prometheus-mysqld-exporter@',
        require       => Package['prometheus-mysqld-exporter'],
    }
}
