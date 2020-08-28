class profile::wmcs::db::wikireplicas::mariadb_config {
    require profile::mariadb::packages_wmf

    class { 'mariadb::config':
        config        => 'profile/wmcs/db/wikireplicas/wikireplicas-my.cnf.erb',
        basedir       => $profile::mariadb::packages_wmf::basedir,
        datadir       => '/srv/sqldata',
        socket        => '/run/mysqld/mysqld.sock',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }
}
