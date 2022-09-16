# SPDX-License-Identifier: Apache-2.0
# @summary Provisions rootless mode buildkitd within a Docker network
#
# @param ensure Whether to have buildkitd present or absent
# @param network Docker network name on which to run the buildkitd container
# @param address Bind to a specific address within the Docker network
# @param port Port to listen on
# @param image Ref to the buildkitd image to run
# @param nameservers DNS nameservers to configure for OCI worker containers.
# @param enable_webproxy Use proxy to access external resources
# @param http_proxy webproxy address to use for http
# @param https_proxy webproxy address to use for https
#
class buildkitd(
    Wmflib::Ensure             $ensure,
    String                     $network,
    Stdlib::IP::Address        $address = '0.0.0.0',
    Stdlib::Port               $port = 1234,
    String                     $image = 'docker-registry.wikimedia.org/buildkitd:latest',
    Array[Stdlib::IP::Address] $nameservers = [],
    Boolean                    $enable_webproxy = false,
    String                     $http_proxy = 'http://webproxy:8080',
    String                     $https_proxy = 'http://webproxy:8080',
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

    file { '/etc/buildkitd.toml':
        ensure  => stdlib::ensure($ensure, 'file'),
        content => template('buildkitd/buildkitd.toml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    systemd::service { 'buildkitd':
        ensure  => $ensure,
        content => template('buildkitd/buildkitd.service.erb'),
        require => [
            Class['docker'],
            User['buildkitd'],
            File['/etc/buildkitd.toml'],
        ]
    }
}
