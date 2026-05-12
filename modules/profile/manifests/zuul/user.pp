# SPDX-License-Identifier: Apache-2.0
# set up system user and group for new zuul
class profile::zuul::user {

    group { 'zuul':
        ensure => present,
        uid    => 923,
        name   => 'zuul',
        system => true,
    }

    user { 'zuul':
        ensure  => present,
        uid     => 923,
        system  => true,
        groups  => 'docker',
        require => [
            Group['zuul'],
        ],
    }
}
