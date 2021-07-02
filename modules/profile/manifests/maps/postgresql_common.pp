# = Class: profile::maps::postgresql_common
#
# Manages the postgresql configuration commone to master and replicas.
#
# == Parameters:
# - $shared_buffers: postgresql shared buffer. Default: 7680MB (should only be
#                    overriden for tests or VMs on lab).
# - $maintenance_work_mem: postgresql maintenance work mem. Default: 4GB
#                    (should only be overriden for tests or VMs on lab).
# - $chgrp_log: chgrp the postgresql log to maps-admin group. Disable in
#                    deployment-prep.
class profile::maps::postgresql_common(
    String $shared_buffers       = lookup('profile::maps::postgresql_common::shared_buffers', { 'default_value' => '7680MB' }),
    String $maintenance_work_mem = lookup('profile::maps::postgresql_common::maintenance_work_mem', { 'default_value' => '4GB' }),
    Boolean $chgrp_log = lookup('profile::maps::postgresql_common::chown_logfile', {'default_value' => true}),
){

    class { '::postgresql::postgis': }

    $pgversion = $::lsbdistcodename ? {
        'buster'  => 11,
        'stretch' => 9.6,
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

    if $chgrp_log {
        # TODO: Figure out a better way to do this
        # Ensure postgresql logs as maps-admin to allow maps-admin to read them
        # Rely on logrotate's copytruncate policy for postgres for the rest of the
        # log file
        file { "/var/log/postgresql/postgresql-${pgversion}-main.log":
          group => 'maps-admins',
        }
    }
    ferm::service { 'kubepods-maps-postgres':
        proto  => 'tcp',
        port   => '5432',
        srange => '$KUBEPODS_NETWORKS',
    }
}
