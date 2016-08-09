class role::puppetmaster::puppetdb {
    include ::base::firewall
    include ::passwords::postgres
    include standard

    system::role { 'role::puppetmaster::puppetdb':
        ensure      => 'present',
        description => 'PuppetDB server',
    }

    ganglia::plugin::python { 'diskstat': }

    ferm::service { 'postgresql':
        proto  => 'tcp',
        port   => 5432,
        srange => '$DOMAIN_NETWORKS',
    }

    ferm::service { 'puppetdb':
        proto  => 'tcp',
        port   => 8080,
        srange => '$DOMAIN_NETWORKS',
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::postgres::ganglia_user,
        pgstats_pass => $passwords::postgres::ganglia_pass,
    }

    # Tuning
    file { '/etc/postgresql/9.4/main/tuning.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/role/puppetdb/tuning.conf',
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    include ::puppetmaster::puppetdb
}
