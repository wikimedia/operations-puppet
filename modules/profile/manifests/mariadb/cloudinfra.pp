class profile::mariadb::cloudinfra (
    Boolean $master = hiera('profile::mariadb::cloudinfra::master'),
    Array[Stdlib::Fqdn] $puppetmasters = lookup('profile::mariadb::cloudinfra::puppetmasters'),
    Array[Stdlib::Fqdn] $cloudinfra_dbs = lookup('profile::mariadb::cloudinfra::cloudinfra_dbs'),
) {
    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    $puppetmasters_joined = join($puppetmasters.map |$puppetmaster| { "@resolve(${$puppetmaster})" }, ' ')
    ferm::service { 'wmcs_puppetmasters':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => "(${$puppetmasters_joined})",
    }

    $cloudinfra_dbs_joined = join($cloudinfra_dbs.map |$db| { "@resolve(${$db})" }, ' ')
    ferm::service { 'mariadb_replication':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => "(${$cloudinfra_dbs_joined})",
    }

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class { 'mariadb::service': }

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        basedir   => $profile::mariadb::packages_wmf::basedir,
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
