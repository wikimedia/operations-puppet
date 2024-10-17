# SPDX-License-Identifier: Apache-2.0
# Grafana Loki is a set of components that can be composed into a fully featured logging stack.
# Params:
#   $config: Hash of configuration options written to /etc/loki/loki-local-config.yaml
#   $ensure: 'present' (installed) or 'absent' (uninstalled)
#   $version: (optional) the package version to ensure
class grafana::loki (
  Hash             $config = {},
  Wmflib::Ensure   $ensure = 'present',
  Optional[String] $version = undef

) {

  $_package_ensure = $ensure ? {
    'absent' => 'absent',
    default  => pick($version, $ensure)
  }

  package { 'grafana-loki':
    ensure => $_package_ensure
  }

  if ($config) {
    file { '/etc/loki/loki-local-config.yaml':
      mode    => '0644',
      content => to_yaml($config),
      require => Package['grafana-loki']
    }
  }

  systemd::service { 'grafana-loki':
      ensure   => present,
      content  => init_template('grafana-loki', 'systemd_override'),
      override => true,
      restart  => true,
  }

  profile::auto_restarts::service { 'grafana-loki': }
}
