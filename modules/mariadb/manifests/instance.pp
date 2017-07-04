# Setups additional instances for hosts that hosts more
# than one instance
define mariadb::instance(
    $port,
    $datadir = 'undefined',
    $tmpdir  = 'undefined',
    $socket  = 'undefined',
) {
    if $datadir == 'undefined' {
        $datadir = "/srv/sqldata.${title}"
    }
    if $tmpdir == 'undefined' {
        $tmpdir  = '/srv/tmp.${title}'
    }
    if $tmpdir == 'undefined' {
        $socket  = '/run/mysqld/mysqld.${title}.sock'
    }

    file { $datadir:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { $tmpdir:
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
}
