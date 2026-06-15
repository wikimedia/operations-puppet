# Beta Cluster DB server
class profile::mariadb::beta {

    include profile::base::production
    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include passwords::misc::scripts
    include mariadb::stock_heartbeat

    $basedir = $profile::mariadb::packages_wmf::basedir
    $datadir = '/srv/sqldata'

    class { 'mariadb::config':
        basedir => $basedir,
        datadir => $datadir,
        config  => 'role/mariadb/mysqld_config/beta.my.cnf.erb',
    }

    # Bootstrap the system schema (mysql.* privilege tables etc.) on a fresh
    # host. Gated on the system schema directory so it only runs on an empty datadir.
    exec { 'mariadb_beta_mysql_install_db':
        command => "${basedir}/scripts/mysql_install_db",
        cwd     => $basedir,
        creates => "${datadir}/mysql",
        require => Class['mariadb::config'],
        before  => Class['mariadb::service'],
    }

    class { 'mariadb::service':
        ensure  => 'running',
        manage  => true,
        enable  => true,
        require => Class['mariadb::config'],
    }

    $password = $passwords::misc::scripts::mysql_beta_root_pass

    $prompt = 'BETA'
    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }

    # MariaDB replica provisioning tools
    file { '/usr/local/bin/receive_replica.sh':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/beta/receive_replica.sh',
    }

    file { '/usr/local/bin/stream_master.sh':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/beta/stream_master.sh',
    }
}
