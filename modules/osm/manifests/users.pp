# SPDX-License-Identifier: Apache-2.0
class osm::users {
    if debian::codename::ge('bookworm') {
        systemd::sysuser { 'osm':
            usertype => 'group',
        }

        systemd::sysuser { 'osmupdater':
            additional_groups => ['osm'],
        }

        systemd::sysuser { 'osmimporter':
            additional_groups => ['osm'],
        }
    } else {
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
}
