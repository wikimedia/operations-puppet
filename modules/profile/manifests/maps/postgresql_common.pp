# SPDX-License-Identifier: Apache-2.0
# = Class: profile::maps::postgresql_common
#
# Manages the postgresql configuration commone to master and replicas.
#
# == Parameters:
# - $shared_buffers: postgresql shared buffer. Default: 7680MB
# - $maintenance_work_mem: postgresql maintenance work mem. Default: 4GB
#                    (should only be overriden for tests or VMs on lab).
# - $max_worker_processes: maximum worker processes - can be up to numcpus
class profile::maps::postgresql_common(
    String  $shared_buffers        = lookup('profile::maps::postgresql_common::shared_buffers', { 'default_value' => '7680MB' }),
    String  $effective_cache_size  = lookup('profile::maps::postgresql_common::effective_cache_size', { 'default_value' => '22GB' }),
    String  $maintenance_work_mem  = lookup('profile::maps::postgresql_common::maintenance_work_mem', { 'default_value' => '4GB' }),
    Integer $max_worker_processes  = lookup('profile::maps::postgresql_common::max_worker_processes', { 'default_value' => 8 }),
){

    class { '::postgresql::postgis': }

    $pgversion = $::lsbdistcodename ? {
        'buster'  => 11,
        'bullseye' => 13,
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

    ferm::service { 'kubepods-maps-postgres':
        proto  => 'tcp',
        port   => '5432',
        srange => '($WIKIKUBE_KUBEPODS_NETWORKS $STAGING_KUBEPODS_NETWORKS)',
    }
}
