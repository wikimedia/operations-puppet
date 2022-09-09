class profile::mariadb::cloudinfra (
    Boolean             $master         = lookup('profile::mariadb::cloudinfra::master'),
    Array[Stdlib::Fqdn] $enc_servers    = lookup('profile::mariadb::cloudinfra::enc_servers'),
    Array[Stdlib::Fqdn] $cloudinfra_dbs = lookup('profile::mariadb::cloudinfra::cloudinfra_dbs'),
) {
    if debian::codename::ge('bullseye') {
        # for bullseye and newer (cloudinfra-db03+), use a Cinder volume for MariaDB storage
        include ::profile::labs::cindermount::srv
    }

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    ferm::service { 'enc-clients':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => "(@resolve((${enc_servers.join(' ')})))",
    }

    ferm::service { 'mariadb_replication':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => "(@resolve((${cloudinfra_dbs.join(' ')})))",
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
