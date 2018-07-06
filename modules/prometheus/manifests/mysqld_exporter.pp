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
# [*arguments*]
#   Additional command line arguments for prometheus-mysqld-exporter.

define prometheus::mysqld_exporter (
    $client_socket = '/tmp/mysql.sock',
    $client_user = 'prometheus',
    $client_password = '',
    $arguments = '',
) {
    require_package('prometheus-mysqld-exporter')

    file { '/var/lib/prometheus':
        ensure => directory,
        mode   => '0550',
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    # default .my.cnf location (i.e. $HOME/.my.cnf)
    file { '/var/lib/prometheus/.my.cnf':
        ensure  => present,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('prometheus/mysqld_exporter.cnf.erb'),
        require => [
          Package['prometheus-mysqld-exporter'],
          File['/var/lib/prometheus'],
        ],
        notify  => Service['prometheus-mysqld-exporter'],
    }

    file { '/etc/default/prometheus-mysqld-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
        notify  => Service['prometheus-mysqld-exporter'],
    }

    service { 'prometheus-mysqld-exporter':
        ensure  => running,
        require => [Package['prometheus-mysqld-exporter'],
                    File['/var/lib/prometheus/.my.cnf']],
    }

    base::service_auto_restart { 'prometheus-mysqld-exporter': }
}
