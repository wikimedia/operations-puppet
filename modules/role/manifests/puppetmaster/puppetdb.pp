# filtertags: labs-project-deployment-prep labs-project-automation-framework labs-project-toolsbeta
class role::puppetmaster::puppetdb (
    $shared_buffers = '7680MB'
) {
    include ::standard
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

    ferm::service { 'postgresql_puppetdb':
        proto  => 'tcp',
        port   => 5432,
        srange => "@resolve((${slave_range}))",
    }

    # Only the TLS-terminating nginx proxy will be exposed
    $puppetmasters_ferm = inline_template('<%= scope.function_hiera([\'puppetmaster::servers\']).values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')
    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => "@resolve((${puppetmasters_ferm}))",
    }

    if $::standard::has_ganglia {
        class { 'postgresql::ganglia':
            pgstats_user => $passwords::postgres::ganglia_user,
            pgstats_pass => $passwords::postgres::ganglia_pass,
        }

        ganglia::plugin::python { 'diskstat': }
    }

    # Tuning
    file { '/etc/postgresql/9.4/main/tuning.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('role/puppetdb/tuning.conf.erb'),
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
