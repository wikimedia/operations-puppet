# Beta Cluster DB server
class profile::mariadb::beta {

    include ::profile::standard
    include mariadb::packages_wmf
    include passwords::misc::scripts
    include mariadb::stock_heartbeat

    # This is essentially the same volume created by role::labs::lvm::srv but
    # ensures it will be created before mariadb is installed and leaves some
    # LVM extents free for a possible second volume for the tmpdir.
    # (see T117446)
    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv',
        size    => '80%FREE',
        before  => Class['mariadb::packages_wmf'],
    }

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/beta.my.cnf.erb',
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
}

