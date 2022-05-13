# SPDX-License-Identifier: Apache-2.0
# @summary Provisions rootless mode buildkitd within a Docker network
#
# @param ensure Whether to have buildkitd present or absent
# @param network Docker network name on which to run the buildkitd container
# @param address Bind to a specific address within the Docker network
# @param port Port to listen on
# @param image Ref to the buildkitd image to run
#
class buildkitd(
    Wmflib::Ensure      $ensure,
    String              $network,
    Stdlib::IP::Address $address = '0.0.0.0',
    Stdlib::Port        $port = 1234,
    String              $image = 'docker-registry.wikimedia.org/buildkitd:latest',
){
    group { 'buildkitd':
        ensure => $ensure,
        name   => 'buildkitd',
        system => true,
    }

    user { 'buildkitd':
        ensure  => $ensure,
        system  => true,
        groups  => 'docker',
        require => [
            Class['docker'],
            Group['buildkitd'],
        ],
    }

    systemd::service { 'buildkitd':
        ensure  => $ensure,
        content => template('buildkitd/buildkitd.service.erb'),
        require => [
            Class['docker'],
            User['buildkitd'],
        ]
    }
}
