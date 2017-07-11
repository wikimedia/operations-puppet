# Setups additional instances for hosts that hosts more
# than one instance
define mariadb::instance(
    $port,
    $datadir = 'undefined',
    $tmpdir  = 'undefined',
    $socket  = 'undefined',
) {
    if $datadir == 'undefined' {
        $datadir_instance = "/srv/sqldata.${title}"
    } else {
        $datadir_instance = $datadir
    }
    if $tmpdir == 'undefined' {
        $tmpdir_instance = "/srv/tmp.${title}"
    } else {
        $tmpdir_instance = $tmpdir
    }
    if $tmpdir == 'undefined' {
        $socket_instance = "/run/mysqld/mysqld.${title}.sock"
    } else {
        $socket_instance = $socket
    }

    file { $datadir_instance:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { $tmpdir_instance:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { "/etc/mysql/mysqld.conf.d/${title}.cnf":
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mariadb/instance.cnf.erb'),
    }

    # TODO: Allow non-defaults replication monitoring, such as
    # allowing it to be critical
    mariadb::monitor_replication{ $title:
        socket => $socket_instance,
    }
}
