# = Class: profile::maps::postgresql_common
#
# Manages the postgresql configuration commone to master and slaves.
#
# == Parameters:
# - $shared_buffers: postgresql shared buffer. Default: 7680MB (should only be
#                    overriden for tests or VMs on lab).
# - $maintenance_work_mem: postgresql maintenance work mem. Default: 4GB
#                    (should only be overriden for tests or VMs on lab).
class profile::maps::postgresql_common(
    $shared_buffers = hiera('profile::maps::postgresql_common::shared_buffers', '7680MB'),
    $maintenance_work_mem = hiera('profile::maps::postgresql_common::maintenance_work_mem', '4GB'),
) {
    class { '::postgresql::postgis': }

    $pgversion = $::lsbdistcodename ? {
        'stretch' => '9.6',
        'jessie'  => '9.4',
    }

    # Tuning
    file { "/etc/postgresql/${pgversion}/main/tuning.conf":
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
    file { "/var/log/postgresql/postgresql-${pgversion}-main.log":
        group => 'maps-admins',
    }
}
