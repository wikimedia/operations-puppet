# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::varnishkafka_exporter (
  Hash $stats_default = lookup('profile::prometheus::varnishkafka_exporter::stats_default'),
){
  class { 'prometheus::varnishkafka_exporter':
    stats_default => $stats_default
  }
}
