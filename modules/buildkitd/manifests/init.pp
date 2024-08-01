# SPDX-License-Identifier: Apache-2.0
# @summary Provisions buildkitd within a Docker network
#
# @param ensure Whether to have buildkitd present or absent
# @param network Docker network name on which to run the buildkitd container
# @param address Bind to a specific address within the Docker network
# @param port Port to listen on
# @param image Ref to the buildkitd image to run
# @param nameservers DNS nameservers to configure for OCI worker containers.
# @param environment Environment variables to set for the buildkitd container.
# @param gckeepstorage Local buildkitd cache to keep after garbage collection (e.g. "10Gb")
# @param cni_pool_size Size of the preallocated pool of CNI network namespaces.
# @param dockerfile_frontend_enabled Enable/disable the Dockerfile frontend
# @param gateway_frontend_enabled Boolean Enable/disabled the gateway.v0 frontend
# @param allowed_gateway_sources The list of allowed gateway image repos (without tags).
#        An empty list means all gateway images are allowed.
#
class buildkitd(
    Wmflib::Ensure           $ensure,
    String                   $network,
    Stdlib::IP::Address      $address = '0.0.0.0',
    Stdlib::Port             $port = 1234,
    String                   $image = 'docker-registry.wikimedia.org/repos/releng/buildkit:wmf-v0.15.1-1',
    Array[Stdlib::Host]      $nameservers = [],
    Wmflib::POSIX::Variables $environment = {},
    Optional[String]         $gckeepstorage = undef,
    Integer                  $cni_pool_size = 20,
    Optional[Boolean]        $dockerfile_frontend_enabled = false,
    Optional[Boolean]        $gateway_frontend_enabled = true,
    Optional[Array[String]]  $allowed_gateway_sources = [],
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

    file { '/etc/default/buildkitd':
        ensure  => stdlib::ensure($ensure, 'file'),
        content => template('buildkitd/buildkitd.env.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    systemd::service { 'buildkitd':
        ensure    => $ensure,
        content   => template('buildkitd/buildkitd.service.erb'),
        restart   => true,
        require   => [
            Class['docker'],
            User['buildkitd'],
        ],
        subscribe => File['/etc/buildkitd.toml', '/etc/default/buildkitd'],
    }
}
