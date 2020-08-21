class profile::wmcs::db::wikireplicas::mariadb_config {
    if os_version('debian == buster') {
        $basedir = '/opt/wmf-mariadb104/'
    }
    else {
        $basedir = '/opt/wmf-mariadb101/'
    }
    class { 'mariadb::config':
        config        => 'profile/wmcs/db/wikireplicas/wikireplicas-my.cnf.erb',
        basedir       => $basedir,
        datadir       => '/srv/sqldata',
        socket        => '/run/mysqld/mysqld.sock',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }
}
