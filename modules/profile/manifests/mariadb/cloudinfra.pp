class profile::mariadb::cloudinfra (
    Boolean $master = hiera('profile::mariadb::cloudinfra::master'),
) {
    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    ferm::service { 'wmcs_puppetmasters':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => '(@resolve(cloud-puppetmaster-01.cloudinfra.eqiad.wmflabs) @resolve(cloud-puppetmaster-02.cloudinfra.eqiad.wmflabs))',
    }

    ferm::service { 'mariadb_replication':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => '(@resolve(cloudinfra-db01.cloudinfra.eqiad.wmflabs) @resolve(cloudinfra-db02.cloudinfra.eqiad.wmflabs))',
    }

    class { 'mariadb::packages_wmf': }
    class { 'mariadb::service': }

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        basedir   => '/opt/wmf-mariadb101',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        ssl       => 'puppet-cert',
        read_only => $read_only,
    }

    class { 'mariadb::heartbeat':
        datacenter => $::site,
        enabled    => $master,
    }
}