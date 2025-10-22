# SPDX-License-Identifier: Apache-2.0
# Research host
class profile::mariadb::research {
    group { 'mysql':
        ensure => present,
        name   => 'mysql',
        system => true,
    }

    user { 'mysql':
        ensure => present,
        system => true,
        groups => 'mysql',
        home   => '/nonexistent',
    }

    firewall::service { 'mariadb':
        proto    => 'tcp',
        port     => 3306,
        src_sets => ['INTERNAL'],
    }
}
