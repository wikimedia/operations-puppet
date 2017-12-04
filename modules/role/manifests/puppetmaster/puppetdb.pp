# filtertags: labs-project-deployment-prep labs-project-automation-framework labs-project-toolsbeta
class role::puppetmaster::puppetdb (
    $shared_buffers = '7680MB'
) {
    include ::standard
    include ::base::firewall
    include ::passwords::postgres

    $pgversion = $::lsbdistcodename ? {
        'stretch' => '9.6',
        'jessie'  => '9.4',
    }

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
        class { 'postgresql::slave::monitoring':
            pg_master   => $master,
            pg_user     => 'replication',
            pg_password => $pg_password,
        }
    }

    system::role { "puppetmaster::puppetdb (postgres ${role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }

    ferm::service { 'postgresql_puppetdb':
        proto  => 'tcp',
        port   => 5432,
        srange => "@resolve((${slave_range}))",
    }

    # Only the TLS-terminating nginx proxy will be exposed
    $puppetmasters_ferm = inline_template('<%= scope.call_function(:hiera, [\'puppetmaster::servers\']).values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')
    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => "@resolve((${puppetmasters_ferm}))",
    }

    ferm::service { 'puppetdb-cumin':
        proto  => 'tcp',
        port   => 443,
        srange => '$CUMIN_MASTERS',
    }

    # Tuning
    file { "/etc/postgresql/${pgversion}/main/tuning.conf":
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

    include ::profile::puppetmaster::puppetdb::monitoring
    $prometheus_java_opts = $::profile::puppetmaster::puppetdb::monitoring::prometheus_java_opts

    $jvm_opts = hiera('puppetmaster::puppetdb::jvm_opts', '-Xmx4G')

    # The JVM heap size has been raised to 6G for T170740
    class { '::puppetmaster::puppetdb':
        master   => $master,
        jvm_opts => "${jvm_opts} ${prometheus_java_opts}",
        require  => Class['profile::puppetmaster::puppetdb::monitoring'],
    }
}
