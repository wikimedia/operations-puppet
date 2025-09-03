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
    $enable_heartbeat_monitoring = true,
) {
    #We only want to restart if the service is running
    #(which it won't be if mariadb isn't)
    exec { 'systemctl try-restart prometheus-mysqld-exporter':
        refreshonly => true,
        path        => '/usr/bin',
    }

    # On Trixie the exporter errors out because it can't
    #  find the config file. We need to give it a hint.
    $cnfarg = debian::codename::ge('trixie') ? {
        true    => '--config.my-cnf /var/lib/prometheus/.my.cnf',
        default => '',
    }

    ensure_packages('prometheus-mysqld-exporter', {'notify' => Exec['systemctl try-restart prometheus-mysqld-exporter']})

    # Set permissions to 0755 similarly to the Debian package defaults [to prevent breaking ferm monitoring]
    # See T403617 T403615
    file { '/var/lib/prometheus':
        ensure  => directory,
        # set permissions to `rwxr-xr-x`
        mode    => '0755',
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
--no-collect.info_schema.tables"
    }
    else {
        $options = $arguments
    }
    if $enable_heartbeat_monitoring == true {
        $final_options = "${options} \
--collect.heartbeat \
--collect.heartbeat.utc \
${cnfarg}"
    } else {
        $final_options = "${options} \
${cnfarg}"
    }
    file { '/etc/default/prometheus-mysqld-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${final_options}\"",
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
