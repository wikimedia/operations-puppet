# @summary Cloud VPS eqiad1 specific tweaks to the base Pontoon setup
# SPDX-License-Identifier: Apache-2.0
class profile::pontoon::provider::cloud_vps (
  Array[Stdlib::Fqdn] $metricsinfra_prometheus_nodes = lookup('metricsinfra_prometheus_nodes', {default_value => []}),
) {
  if !empty($metricsinfra_prometheus_nodes) {
    ferm::rule { 'metricsinfra-prometheus-all':
      rule => "saddr @resolve((${metricsinfra_prometheus_nodes.join(' ')})) ACCEPT;"
    }
  }
}
