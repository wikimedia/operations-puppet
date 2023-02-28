# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::postgres::primary (
    Stdlib::Unixpath $root_dir = lookup('profile::wmcs::services::postgres::root_dir', {default_value => '/srv/postgres'}),
) {
    $pgversion = debian::codename() ? {
        'buster' => 11,
    }

    file { "/etc/postgresql/${pgversion}/main/tuning.conf":
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/wmcs/db/postgres/tuning.conf',
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    class {'::postgresql::postgis': }
    include ::profile::prometheus::postgres_exporter

    class { 'postgresql::master':
        pgversion => $pgversion,
        includes  => ['tuning.conf'],
        root_dir  => $root_dir,
    }
}
