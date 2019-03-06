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

    # Set default arguments
    if $arguments == '' {
        if os_version('debian >= buster') {
            $options = "--collect.global_status \
--collect.global_variables \
--collect.info_schema.processlist \
--collect.slave_status \
--no-collect.info_schema.tables"
        } else {
            $options = "-collect.global_status \
-collect.global_variables \
-collect.info_schema.processlist \
-collect.info_schema.processlist.min_time 0 \
-collect.slave_status \
-collect.info_schema.tables false"
        }
    } else {
        $options = $arguments
    }

    file { '/etc/default/prometheus-mysqld-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${options}\"",
        notify  => Service['prometheus-mysqld-exporter'],
    }

    service { 'prometheus-mysqld-exporter':
        ensure  => running,
        require => [Package['prometheus-mysqld-exporter'],
                    File['/var/lib/prometheus/.my.cnf']],
    }

    if os_version('debian >= jessie') {
        base::service_auto_restart { 'prometheus-mysqld-exporter': }
    }
}
