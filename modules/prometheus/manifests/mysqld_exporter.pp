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

    #We only want to restart if the service is running
    #(which it won't be if mariadb isn't)
    exec { 'systemctl try-restart prometheus-mysqld-exporter':
        refreshonly => true,
        path        => '/usr/bin',
    }

    ensure_packages('prometheus-mysqld-exporter', {'notify' => Exec['systemctl try-restart prometheus-mysqld-exporter']})
    if debian::codename::eq('bullseye') {
      # Needed to get the latest version 0.13 see https://phabricator.wikimedia.org/T369722
      apt::package_from_bpo {'prometheus-mysqld-exporter':
        distro => 'bullseye',
      }
    }

    file { '/var/lib/prometheus':
        ensure  => directory,
        mode    => '0550',
        require => Package['prometheus-mysqld-exporter'],
        owner   => 'prometheus',
        group   => 'prometheus',
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
        notify  => Exec['systemctl try-restart prometheus-mysqld-exporter'],
    }

    # Set default arguments
    if $arguments == '' {
            $options = "--collect.global_status \
--collect.global_variables \
--collect.info_schema.processlist \
--collect.slave_status \
--no-collect.info_schema.tables \
--collect.heartbeat \
--collect.heartbeat.utc"
    }
    else {
        $options = $arguments
    }

    file { '/etc/default/prometheus-mysqld-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${options}\"",
        notify  => Exec['systemctl try-restart prometheus-mysqld-exporter'],
    }

    systemd::unit { 'prometheus-mysqld-exporter':
        ensure   => present,
        override => true,
        restart  => false,
        content  => @(EOT)
            #Ensure the prometheus exporter is (re-)started and stopped
            #with the mariadb service
            [Unit]
            After=mariadb.service
            Requisite=mariadb.service
            | EOT
        ,
    }

    profile::auto_restarts::service { 'prometheus-mysqld-exporter': }
}
