# Beta Cluster Master
# Should add separate role for slaves
class role::mariadb::beta {

    system::role { 'role::mariadb::beta':
        description => 'beta cluster database server',
    }

    include standard
    include mariadb::packages_wmf
    include passwords::misc::scripts

    # This is essentially the same volume created by role::labs::lvm::srv but
    # ensures it will be created before mariadb is installed and leaves some
    # LVM extents free for a possible second volume for the tmpdir.
    # (see T117446)
    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv',
        size    => '80%FREE',
        before  => Class['mariadb::packages'],
    }

    class { 'mariadb::config':
        config  => 'mariadb/beta.my.cnf.erb',
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

