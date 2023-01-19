# SPDX-License-Identifier: Apache-2.0
# @summary generate Prometheus metrics about Puppet CA state
class puppetmaster::ca_monitoring (
  Stdlib::Unixpath $ca_root,
  Wmflib::Ensure   $ensure = present,
) {
  ensure_packages([
    'python3-cryptography',
    'python3-prometheus-client',
  ])

  file { '/usr/local/sbin/prometheus-puppet-ca-exporter':
    ensure => file,
    source => 'puppet:///modules/puppetmaster/ca_monitoring/prometheus-puppet-ca-exporter.py',
    owner  => 'root',
    group  => 'root',
    mode   => '0544',
  }

  systemd::timer::job { 'prometheus-puppet-ca-exporter':
    ensure      => $ensure,
    user        => 'root',
    description => 'exports Puppet CA data as Prometheus metrics',
    command     => "/usr/local/sbin/prometheus-puppet-ca-exporter --outfile /var/lib/prometheus/node.d/puppet-ca.prom --ca-path ${ca_root}",
    interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '5m'},
  }
}
