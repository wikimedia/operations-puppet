# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::postgres::secondary (
    Stdlib::Host $postgres_primary = lookup('profile::wmcs::services::postgres::primary', {default_value => undef}),
    String $replication_pass = lookup('profile::wmcs::services::postgres::replication_pass'),
    Stdlib::Unixpath $root_dir = lookup('profile::wmcs::services::postgres::root_dir', {default_value => '/srv/postgres'}),
){
    include profile::wmcs::services::postgres::common
    class {'::postgresql::postgis': }

    class {'postgresql::slave':
        master_server    => $postgres_primary,
        replication_pass => $replication_pass,
        includes         => ['tuning.conf'],
        root_dir         => $root_dir,
    }
}
