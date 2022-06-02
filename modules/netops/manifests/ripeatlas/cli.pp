# SPDX-License-Identifier: Apache-2.0
class netops::ripeatlas::cli (
  String $http_proxy = undef,
) {
    ensure_packages('ripe-atlas-tools')

    include ::passwords::netops # lint:ignore:wmf_styleguide
    $api_key = $::passwords::netops::ripeatlas_cli_api_key
    $utils = ['adig', 'ahttp', 'antp', 'aping', 'asslcert', 'atraceroute']

    $home = '/var/lib/atlas'

    user { 'atlas':
        ensure     => present,
        system     => true,
        home       => $home,
        shell      => '/bin/bash',
        managehome => true,
    }

    file { ["${home}/.config", "${home}/.config/ripe-atlas-tools"]:
        ensure => directory,
        owner  => 'atlas',
        group  => 'root',
        mode   => '0500',
    }

    file { "${home}/.config/ripe-atlas-tools/rc":
        ensure  => present,
        content => template('netops/ripeatlas-cli-config.erb'),
        owner   => 'atlas',
        group   => 'root',
        mode    => '0400',
    }

    file { '/etc/ripeatlas.alias':
        ensure  => present,
        content => template('netops/ripeatlas-alias.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
