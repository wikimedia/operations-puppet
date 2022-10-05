# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::statsd_exporter (
    Array[Hash] $mappings      = lookup('profile::prometheus::statsd_exporter::mappings'),
    Boolean     $enable_relay  = lookup('profile::prometheus::statsd_exporter::enable_relay', { 'default_value' => true }),
    String      $relay_address = lookup('statsd'),
){

    if $enable_relay {
        $relay_addr = $relay_address
    } else {
        $relay_addr = ''
    }

    class { '::prometheus::statsd_exporter':
        mappings      => $mappings,
        relay_address => $relay_addr,
    }

    # Don't spam conntrack with localhost statsd clients
    ferm::client { 'statsd-exporter-client':
        proto   => 'udp',
        notrack => true,
        port    => '9125',
        drange  => '127.0.0.1',
    }
}
