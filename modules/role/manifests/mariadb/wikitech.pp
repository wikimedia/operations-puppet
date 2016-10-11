# wikitech instance (silver)
class role::mariadb::wikitech {

    system::role { 'role::mariadb::wikitech':
        description => 'Wikitech Database',
    }

    include standard
    include role::mariadb::grants::wikitech
    include role::mariadb::monitor
    include passwords::misc::scripts
    class { 'role::mariadb::groups':
        mysql_group => 'wikitech',
        mysql_role  => 'standalone',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        config  => 'mariadb/wikitech.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
    }

    # mysql monitoring access from tendril (db1011)
    ferm::rule { 'mysql_tendril':
        rule => 'saddr 10.64.0.15 proto tcp dport (3306) ACCEPT;',
    }

    # mysql from deployment master servers and terbium (T98682, T109736)
    ferm::service { 'mysql_deployment_terbium':
        proto  => 'tcp',
        port   => '3306',
        srange => '@resolve((tin.eqiad.wmnet mira.codfw.wmnet terbium.eqiad.wmnet mw1152.eqiad.wmnet))',
    }

    service { 'mariadb':
        ensure  => running,
        require => Class['mariadb::packages_wmf', 'mariadb::config'],
    }
}

