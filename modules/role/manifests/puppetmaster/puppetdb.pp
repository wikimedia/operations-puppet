class role::puppetmaster::puppetdb {
    include standard
    include ::base::firewall
    include ::passwords::postgres

    $master = hiera('puppetmaster::puppetdb::master')
    $slaves = hiera('puppetmaster::puppetdb::slaves')
    $slave_range = join($slaves, ' ')

    $role = $master ? {
        $::fqdn => 'master',
        default => 'slave',
    }

    system::role { "role::puppetmaster::puppetdb (postgres ${role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }

    ganglia::plugin::python { 'diskstat': }

    ferm::service { 'postgresql':
        proto  => 'tcp',
        port   => 5432,
        srange => "@resolve((${slave_range}))",
    }

    # Only the TLS-terminating nginx proxy will be exposed
    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
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

    class { '::puppetmaster::puppetdb::database':
        master => 'master',
    }

    class { '::puppetmaster::puppetdb':
        master => $master,
    }
}
