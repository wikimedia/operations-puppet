# SPDX-License-Identifier: Apache-2.0
# Add support to synchronize prometheus data to other instances for distribution
# upgrade
class profile::prometheus::migration (
  Hash $hosts = lookup('prometheus_migrations', { 'default_value' => {} }),
) {

  $hosts.each |String $datacenter, Hash $data_flows| {
    if $::site == $datacenter {
      rsync::quickdatacopy { "prometheus-migration-${datacenter}":
        ensure               => Wmflib::Ensure($data_flows['ensure']),
        source_host          => $data_flows['src_host'],
        dest_host            => $data_flows['dst_host'],
        chown                => 'prometheus:prometheus',
        auto_sync            => false,
        module_path          => '/srv/prometheus',
        server_uses_stunnel  => true,
        progress             => true,
        use_generic_firewall => true,
      }
    }
  }
}
