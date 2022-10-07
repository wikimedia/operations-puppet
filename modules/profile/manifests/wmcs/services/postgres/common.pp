# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::postgres::common (
    Stdlib::Unixpath $root_dir = lookup('profile::wmcs::services::postgres::root_dir', {default_value => '/srv/postgres'}),
){
    $pgversion = $::lsbdistcodename ? {
        'buster' => 11,
        'stretch' => 9.6,
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
}
