@monitoring::group { 'maps_eqiad': description => 'eqiad maps servers' }
@monitoring::group { 'maps_codfw': description => 'codfw maps servers' }

# This role class sets up a maps server with
# the services kartotherian and tilerator
class role::maps {
    include standard
    include ::postgresql::postgis
    include ::cassandra
    include ::kartotherian
    include ::tilerator

    system::role { 'role::maps':
        description => 'A vector and raster map tile generation service',
    }

    ganglia::plugin::python { 'diskstat': }

    if $::realm == 'production' {
        include lvs::realserver
    }

    # Tuning
    file { '/etc/postgresql/9.4/main/tuning.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/postgres/tuning.conf',
    }
    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }
    # TODO: Figure out a better way to do this
    # Ensure postgresql logs as maps-admin to allow maps-admin to read them
    # Rely on logrotate's copytruncate policy for postgres for the rest of the
    # log file
    file { '/var/log/postgresql/postgresql-9.4-main.log':
        group => 'maps-admins',
    }
}

