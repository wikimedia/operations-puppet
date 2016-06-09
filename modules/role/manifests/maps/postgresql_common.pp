# Sets up Postgres settings common between master and slave roles
class role::maps::postgresql_common {
    include ::postgresql::postgis

    # Tuning
    file { '/etc/postgresql/9.4/main/tuning.conf':
      ensure => 'present',
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/role/maps/tuning.conf',
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
