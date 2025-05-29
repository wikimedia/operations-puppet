# SPDX-License-Identifier: Apache-2.0
# set up system user and group for new zuul
class profile::zuul::user {

    group { 'zuul':
        ensure => present,
        name   => 'zuul',
        system => true,
    }

    user { 'zuul':
        ensure  => present,
        system  => true,
        groups  => 'docker',
        require => [
            Class['docker'],
            Group['zuul'],
        ],
    }
}
