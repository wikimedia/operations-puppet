# == Class profile::docker::builder
#
# This class sets up a docker builder server, where our base images can be built
# and uploaded to the docker registry.
#
# === Parameters
#
# [*proxy_address*] The http proxy address, set to undef if you don't want to use item
#
# [*proxy_port*] The http proxy port; set to undef if not needed
#
# [*registry*] Address of the docker registry.
#
class profile::docker::builder(
    $proxy_address = hiera('profile::docker::builder::proxy_address', undef),
    $proxy_port = hiera('profile::docker::builder::proxy_port', undef),
    $registry = hiera('docker::registry'),
    $username = hiera('docker::registry::username'),
    $password = hiera('docker::registry::password')
    ) {

    class { '::docker::baseimages':
        docker_registry => $registry,
        proxy_address   => $proxy_address,
        proxy_port      => $proxy_port,
        distributions   => ['jessie', 'stretch', 'alpine'],
    }

    require_package('python3-virtualenv', 'virtualenv')

    git::clone { 'operations/docker-images/production-images':
        ensure    => present,
        directory => '/srv/images/production-images'
    }

    file {'/etc/production-images':
        ensure => directory,
        mode   => '0700',
    }

    file { '/etc/production-images/config.yaml':
        ensure  => present,
        content => template('profile/docker/production-images-config.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444'
    }
}
