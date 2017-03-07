class profile::maps::postgresql_common {

    # providing defaults as the only place we want to override them is on labs
    $effective_cache_size = hiera('profile::maps::postgresql_common::effective_cache_size', '22GB')
    $work_mem = hiera('profile::maps::postgresql_common::work_mem', '192MB')
    $shared_buffers = hiera('profile::maps::postgresql_common::shared_buffers', '7680MB')
    $track_activity_query_size = hiera('profile::maps::postgresql_common::track_activity_query_size', '16384')
    $maintenance_work_mem = hiera('profile::maps::postgresql_common::maintenance_work_mem', '4GB')
    $autovacuum_work_mem = hiera('profile::maps::postgresql_common::autovacuum_work_mem', '1GB')

    include ::postgresql::postgis

    # Tuning
    file { '/etc/postgresql/9.4/main/tuning.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/maps/tuning.conf.erb'),
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