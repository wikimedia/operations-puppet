# SPDX-License-Identifier: Apache-2.0
# == Class profile::docker::ml_builder
#
# This class sets up a docker builder server, where our base images can be built
# and uploaded to the docker registry.
#
# === Parameters
# [*registry*] Address of the docker registry.
#
# [*password*] password for the user on the docker registry.
#
# [*docker_pkg*] Boolean value for enabling the docker_pkg component
#
class profile::docker::ml_builder (
  Optional[Stdlib::Host] $proxy_address = lookup('profile::docker::ml_builder::proxy_address', {default_value => undef}),
  Optional[Stdlib::Port] $proxy_port = lookup('profile::docker::ml_builder::proxy_port', {default_value => undef}),
  Stdlib::Host $registry = lookup('docker::registry'),
  String $password = lookup('profile::docker::ml_builder::prod_build_password'),
  Boolean $docker_pkg = lookup('profile::docker::ml_builder::docker_pkg', { default_value => false }),
) {
  class { 'service::deploy::common': }

  if $docker_pkg {
    class { 'docker_pkg': }
  }

  git::clone { 'operations/docker-images/production-images':
    ensure    => present,
    directory => '/srv/production-images',
  }

  docker::credentials { '/root/.docker/config.json':
    owner             => 'root',
    group             => 'root',
    registry          => $registry,
    registry_username => 'ml-build',
    registry_password => $password,
  }

  file {'/etc/production-images':
    ensure => directory,
    mode   => '0700',
  }

  file { '/etc/production-images/config-ml.yaml':
    ensure  => present,
    content => template('profile/docker/production-images-config-ml.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0440'
  }
}
