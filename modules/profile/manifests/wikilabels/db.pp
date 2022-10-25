# SPDX-License-Identifier: Apache-2.0
class profile::wikilabels::db (
    Stdlib::Unixpath $root_dir = lookup('profile::wikilabels::db::root_dir', {default_value => '/srv/postgres'}),
){
    $pgversion = $::lsbdistcodename ? {
        'bullseye' => 11,
    }

    file { "/etc/postgresql/${pgversion}/main/tuning.conf":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/wikilabels/db/postgres/tuning.conf',
        require => Class['postgresql::server'],
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    include ::profile::prometheus::postgres_exporter

    class { 'postgresql::master':
        includes => ['tuning.conf'],
        root_dir => $root_dir,
    }
}
