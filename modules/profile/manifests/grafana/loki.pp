# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::loki
#
# Grafana Loki is a set of components that can be composed into a fully featured logging stack.
# Params:
#   $config: Hash of configuration options (https://grafana.com/docs/loki/latest/configuration)
#   $version: (optional) the package version to ensure
#   $allow_from: (optional) array of hosts that need access to the loki api
class profile::grafana::loki (
  Hash                   $config       = lookup('profile::grafana::loki::config',     { 'default_value' => {} }),
  Optional[String]       $version      = lookup('profile::grafana::loki::version',    { 'default_value' => 'present' }),
  Array[Stdlib::Fqdn]    $allow_from   = lookup('profile::grafana::loki::allow_from', { 'default_value' => [] }),
  Optional[Stdlib::Fqdn] $active_host  = lookup('profile::grafana::active_host',      { 'default_value' => undef }),
  Optional[Stdlib::Fqdn] $standby_host = lookup('profile::grafana::standby_host',     { 'default_value' => undef }),
) {

  unless empty($allow_from) {
    firewall::service { "loki-${config['server']['http_listen_port']}":
      proto  => 'tcp',
      port   => $config['server']['http_listen_port'],
      srange => $allow_from,
    }
  }

  class { '::grafana::loki':
    ensure  => 'present',
    config  => $config,
    version => $version
  }

  # `common.path_prefix` is used to define where the wal, boltdb shipper
  # data, default ruler path, compactor path, and tokens if token
  # persistence is enabled
  $loki_data = pick($config['common']['path_prefix'], '/var/lib/loki')

  file { $loki_data:
    ensure  => 'directory',
    owner   => 'loki',
    group   => 'loki',
    require => Package['grafana-loki']
  }

  # Enables rsync'ing loki data from active host to standby host.
  if $active_host and $standby_host {
    rsync::quickdatacopy { 'loki-data':
      ensure              => present,
      source_host         => $active_host,
      dest_host           => $standby_host,
      module_path         => $loki_data,
      exclude             => 'wal',
      server_uses_stunnel => true,
      chown               => 'loki:loki',
    }
  }
}
