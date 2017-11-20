# Class puppetmaster::puppetdb::database
#
# Sets up the postgresql database
class puppetmaster::puppetdb::database($master) {
    $replication_pass = hiera('puppetdb::password::replication')
    $puppetdb_pass = hiera('puppetdb::password::rw')

    if $master == $::fqdn {
        # We do this for the require in postgres::db
        $require_class = 'postgresql::master'
        class { '::postgresql::master':
            includes => ['tuning.conf'],
            root_dir => '/srv/postgres',
            use_ssl  => true,
        }
        $on_master = true
    } else {
        $require_class = 'postgresql::slave'
        class { '::postgresql::slave':
            includes         => ['tuning.conf'],
            master_server    => $master,
            root_dir         => '/srv/postgres',
            replication_pass => $replication_pass,
            use_ssl          => true,
        }
        $on_master = false
    }
    class { 'postgresql::prometheus':
        require => Class[$require_class],
    }
    # Postgres replication and users
    $postgres_users = hiera('puppetmaster::puppetdb::postgres_users', undef)
    if $postgres_users {
        $postgres_users_defaults = {
            pgversion => 9.4,
            master    => $on_master,
        }
        create_resources(postgresql::user, $postgres_users,
            $postgres_users_defaults)
    }
    # Create the puppetdb user for localhost
    # This works on every server and is used for read-only db lookups
    postgresql::user { 'puppetdb@localhost':
        ensure    => present,
        user      => 'puppetdb',
        database  => 'puppetdb',
        password  => $puppetdb_pass,
        cidr      => "${::ipaddress}/32",
        pgversion => '9.4',
        master    => $on_master,
    }

    # Create the database
    postgresql::db { 'puppetdb':
        owner   => 'puppetdb',
        require => Class[$require_class],
    }

    exec { 'create_tgrm_extension':
        command => '/usr/bin/psql puppetdb -c "create extension pg_trgm"',
        unless  => '/usr/bin/psql puppetdb -c \'\dx\' | /bin/grep -q pg_trgm',
        user    => 'postgres',
        require => Postgresql::Db['puppetdb'],
    }

}
