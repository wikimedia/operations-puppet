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
# [*port*]
#   Port where to listen prometheus requests (it is NOT the port used to connect to mysql-
#   a client_socket is used instead.
#
# [*arguments*]
#   Additional command line arguments for prometheus-mysqld-exporter.

define prometheus::mysqld_exporter_multiinstance (
    $client_socket = '/run/mysqld/mysqld.sock',
    $client_user = 'prometheus',
    $client_password = '',
    $port = 13306,
    $arguments = '',
) {
    require_package('prometheus-mysqld-exporter')

    #file { '/var/lib/prometheus':
    #    ensure => directory,
    #    mode   => '0550',
    #    owner  => 'prometheus',
    #    group  => 'prometheus',
    #}

    file { "/etc/default/prometheus-mysqld-exporter@${title}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"-web.listen-address ${port} -config.my-cnf /var/lib/prometheus/my.${title}.cnf ${arguments}\"",
        notify  => Service['prometheus-mysqld-exporter'],
    }

    # default .my.cnf location (i.e. $HOME/.my.cnf)
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

    file { "/etc/systemd/system/prometheus-mysqld-exporter@${title}.service":
        ensure  => present,
        content => template('prometheus/initscripts/prometheus-mysqld-exporter@.systemd.erb'),
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
        notify  => [
          Exec['systemctl-daemon-reload'],
          Service["prometheus-mysqld-exporter@${title}"],
        ],
    }

    exec { 'systemctl-daemon-reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
    }

    service { "prometheus-mysqld-exporter@${title}":
        ensure  => running,
        require => [Package['prometheus-mysqld-exporter'],
                    File["/var/lib/prometheus/${title}.my.cnf"]],
    }
}
