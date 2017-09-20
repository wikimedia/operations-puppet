# == Class profile::docker::builder
#
# This class sets up a docker builder server, where our base images can be built
# and uploaded to the docker registry.
#
# === Parameters
#
# [*registry*] Address of the docker registry.
#
# [*username*] User to upload images as
#
# [*password*] Password for that user
#
# [*http_proxy*] hash containing information about the http proxy to use
#
# [*proxy_address*] The http proxy address, set to undef if you don't want to use item
#
# [*proxy_port*] The http proxy port; set to undef if not needed
class profile::docker::builder(
    $registry = hiera('docker::registry'),
    $username = hiera('docker::registry::username'),
    $password = hiera('docker::registry::password'),
    $use_apt_proxy = hiera('profile::base::use_apt_proxy', true),
){
    if $use_apt_proxy {
        $debian_security_proxy = "http://webproxy.${::site}.wmnet:8080"
    } else {
        $debian_security_proxy = undef
    }

    # Note proxy-address and proxy-port here refer to a proper apt proxy
    # like apt-cacher-ng, not the http proxy for debian-security
    class { '::docker::baseimages':
        docker_registry => $registry,
        proxy_address   => undef,
        proxy_port      => undef,
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
