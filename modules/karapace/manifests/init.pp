# SPDX-License-Identifier: Apache-2.0
# == Class: karapace

# Sets up a karapace kafka schema registry.
# See https://karapace.io/.
#
# Parameters:
#  [*bootstrap_uri*] - kafka url for karapace to connect to
#  [*server_name*] - hostname of the karapace server
#
# Example usage:
#
# class { 'karapace':
#     bootstrap_uri => 'localhost:9092',
# }

class karapace (
    String $bootstrap_uri = '',
    Stdlib::Host $server_name = $facts['networking']['fqdn'],
) {
    group { 'karapace':
        ensure => present,
        system => true,
    }

    user { 'karapace':
        gid     => 'karapace',
        system  => true,
        require => Group['karapace'],
    }

    ensure_packages('karapace')

    file { '/etc/karapace':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/karapace/karapace.config.json':
        content => template('karapace/karapace.config.json.erb'),
        owner   => 'root',
        group   => 'karapace',
        mode    => '0550',
    }

    systemd::service { 'karapace':
        ensure    => 'present',
        restart   => true,
        content   => file('karapace/initscripts/karapace.service'),
        subscribe => File['/etc/karapace/karapace.config.json'],
    }

    monitoring::service { 'karapace':
        ensure        => present,
        description   => 'karapace http server',
        check_command => 'check_http_port_url!8081!/',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Karapace',
    }
}
