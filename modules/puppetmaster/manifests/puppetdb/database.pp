# Class puppetmaster::puppetdb::database
#
# Sets up the postgresql database
class puppetmaster::puppetdb::database($master) {
    $replication_pass = hiera('puppetdb::password::replication')
    $puppetdb_pass = hiera('puppetdb::password::rw')

    if $master == $::fqdn {
        class { 'postgresql::master':
            includes => ['tuning.conf'],
            root_dir => '/srv/postgres',
            use_ssl  => true,
        }
        # Postgres replication and users
        $postgres_users = hiera('puppetmaster::puppetdb::postgres_users', undef)
        if $postgres_users {
            create_resources(postgresql::user, $postgres_users)
        }
    } else {
        class { 'postgresql::slave':
            includes             => ['tuning.conf'],
            master_server        => $master,
            root_dir             => '/srv/postgres',
            replication_password => $::passwords::postgres::replication_pass,
            use_ssl              => true,
        }
    }


    # Create the puppetdb user for localhost
    # This works on every server and is used for read-only db lookups
    postgresql::user { 'puppetdb@localhost':
        ensure   => present,
        user     => 'puppetdb',
        password => $puppetdb_pass,
        cidr     => $::main_ipaddress,
        database => 'puppetdb',
    }

    # Create the database
    postgresql::db { 'puppetdb':
        owner => 'puppetdb',
    }

    exec { 'create_tgrm_extension':
        command => '/usr/bin/psql puppetdb -c "create extension pg_trgm"',
        unless  => '/usr/bin/psql puppetdb -c \'\dx\' | /bin/grep -q pg_trgm',
        user    => 'postgres',
        require => Postgresql::Db['puppetdb']
    }

}
