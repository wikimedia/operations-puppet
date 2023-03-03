# SPDX-License-Identifier: Apache-2.0
# @summary Provision docker registry to act as a image proxy
#
# @param ensure Whether to have the registry present or absent
# @param port Port to listen on
# @param image Ref to the registry image to run
# @param environment Environment variables to set for the registry container.
# @param registry_volume directory used to store registry on host.
#
class gitlab_runner::registry(
    Wmflib::Ensure           $ensure,
    Stdlib::Port             $port = 5000,
    String                   $image = 'docker-registry.wikimedia.org/registry:2',
    Wmflib::POSIX::Variables $environment = {},
    Stdlib::Unixpath         $registry_volume = '/var/lib/docker-registry',
){

    file { '/etc/default/registry':
        ensure  => stdlib::ensure($ensure, 'file'),
        content => template('gitlab_runner/registry.env.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    systemd::service { 'registry':
        ensure  => $ensure,
        content => template('gitlab_runner/registry.service.erb'),
        restart => true,
        require => [
            Class['docker'],
        ],
    }
}
