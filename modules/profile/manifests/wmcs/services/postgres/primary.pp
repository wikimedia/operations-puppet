# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::services::postgres::primary (
    Optional[Stdlib::Host] $postgres_secondary = lookup('profile::wmcs::services::postgres::secondary', {default_value => undef}),
    Optional[String] $replication_pass = lookup('profile::wmcs::services::postgres::replication_pass', {default_value => undef}),
    Stdlib::Unixpath $root_dir = lookup('profile::wmcs::services::postgres::root_dir', {default_value => '/srv/postgres'}),
){
    include profile::wmcs::services::postgres::common
    class {'::postgresql::postgis': }
    include ::profile::prometheus::postgres_exporter

    class { 'postgresql::master':
        includes => ['tuning.conf'],
        root_dir => $root_dir,
    }

    if $postgres_secondary {
        $postgres_secondary_v4 = ipresolve($postgres_secondary, 4)
        if $postgres_secondary_v4 {
            postgresql::user { "replication@${postgres_secondary}-v4":
                ensure   => 'present',
                user     => 'replication',
                password => $replication_pass,
                cidr     => "${postgres_secondary_v4}/32",
                type     => 'host',
                method   => 'md5',
                attrs    => 'REPLICATION',
                database => 'all',
            }
        }
    }
}
