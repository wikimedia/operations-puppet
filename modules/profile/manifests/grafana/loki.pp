# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::loki
#
# Grafana Loki is a set of components that can be composed into a fully featured logging stack.
# Params:
#   $config: Hash of configuration options (https://grafana.com/docs/loki/latest/configuration)
#   $version: (optional) the package version to ensure
#   $allow_from: (optional) array of hosts that need access to the loki api
class profile::grafana::loki (
  Hash                $config     = lookup('profile::grafana::loki::config',        { 'default_value' => {} }),
  Optional[String]    $version    = lookup('profile::grafana::loki::version',       { 'default_value' => 'present' }),
  Array[Stdlib::Fqdn] $allow_from = lookup('profile::grafana::loki::allow_from',    { 'default_value' => [] })
) {

  unless empty($allow_from) {
    ferm::service { "loki-${config['server']['http_listen_port']}":
      proto  => 'tcp',
      port   => $config['server']['http_listen_port'],
      srange => "@resolve((${allow_from.join(' ')}))",
    }
  }

  class { '::grafana::loki':
    ensure  => 'present',
    config  => $config,
    version => $version
  }

  file { '/var/lib/loki':
    ensure  => 'directory',
    owner   => 'loki',
    group   => 'loki',
    require => Package['grafana-loki']
  }

}
