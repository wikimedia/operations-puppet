# SPDX-License-Identifier: Apache-2.0
class profile::ci::shipyard(
    Stdlib::Fqdn $registry = lookup('docker::registry'),
    String $password = lookup('profile::ci::shipyard::ci_build_user_password'),
    Optional[Stdlib::HTTPUrl] $http_proxy = lookup('http_proxy', {default_value => undef}),
){

    class { '::docker_pkg': }

    file { '/etc/docker-pkg/':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    # TODO: make jenkins able to read this file as well?
    file { '/etc/docker-pkg/integration.yaml':
        ensure  => present,
        content => template('profile/ci/shipyard/docker-pkg-integration-config.yaml.erb'),
        owner   => 'root',
        group   => 'contint-admins',
        mode    => '0440'
    }
}
