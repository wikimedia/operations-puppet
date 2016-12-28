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

    # Monitor the Postgresql replication lag
    if $role == 'slave' {
        $pg_password = hiera('puppetdb::password::replication')
        $critical = 1800
        $warning = 300
        $command = "/usr/lib/nagios/plugins/check_postgres_replication_lag.py \
    -U replication -P ${pg_password} -m ${master} -D template1 -C ${critical} -W ${warning}"
        nrpe::monitor_service { 'postgres-rep-lag':
            description  => 'Postgres Replication Lag',
            nrpe_command => $command,
        }
    }

    system::role { "role::puppetmaster::puppetdb (postgres ${role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }

    ganglia::plugin::python { 'diskstat': }

    ferm::service { 'postgresql_puppetdb':
        proto  => 'tcp',
        port   => 5432,
        srange => "@resolve((${slave_range}))",
    }

    # Only the TLS-terminating nginx proxy will be exposed
    # TODO: Use map() once we migrate to the future parser
    # It should have been
    #
    # $puppetmasters = map(values(hiera('puppetmaster::servers')) |p| { p['worker'] })
    #
    # Instead, we will have to jump through hoops (templates, yaml parsing,
    # parser functions) for this simple thing. So don't and just hardcode it.
    #  Does it suck ? Yes it does. But we are not going through all that
    $puppetmasters = [
        'puppetmaster1001.eqiad.wmnet',
        'puppetmaster1002.eqiad.wmnet',
        'puppetmaster2001.codfw.wmnet',
        'puppetmaster2002.codfw.wmnet',
        'rhodium.eqiad.wmnet',
    ]
    $puppetmasters_ferm = join($puppetmasters, ' ')
    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => "@resolve((${puppetmasters_ferm}))",
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::postgres::ganglia_user,
        pgstats_pass => $passwords::postgres::ganglia_pass,
    }

    # Tuning
    if $::realm == 'production' {
        file { '/etc/postgresql/9.4/main/tuning.conf':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/role/puppetdb/tuning.conf',
        }
    } else {
        # tuning.conf is tailored for the actual production hosts
        # PuppetDB runs on.  For Labs, rather than trying to optimize
        # for possibly vastly different environments (small vs. large
        # instances, instances with only PuppetDB running or other
        # applications as well, etc.), we rely on PostgreSQL defaults
        # instead.
        file { '/etc/postgresql/9.4/main/tuning.conf':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => '',
        }
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    class { '::puppetmaster::puppetdb::database':
        master => $master,
    }

    class { '::puppetmaster::puppetdb':
        master => $master,
    }
}
