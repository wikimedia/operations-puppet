# SPDX-License-Identifier: Apache-2.0
class osm::users {
    group { 'osm':
        ensure => present,
        system => true,
    }

    user { 'osmupdater':
        ensure => present,
        system => true,
        groups => 'osm',
        home   => '/nonexistent',
    }

    user { 'osmimporter':
        ensure => present,
        system => true,
        groups => 'osm',
        home   => '/nonexistent',
    }
}
