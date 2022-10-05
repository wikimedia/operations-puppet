# SPDX-License-Identifier: Apache-2.0
# == Class: profile::prometheus::varnish_exporter
#
# The profile sets up the prometheus exporter for varnish frontend on tcp/9331
#
# === Parameters
# [*nodes*] List of prometheus nodes
#

class profile::prometheus::varnish_exporter {
    prometheus::varnish_exporter{ 'frontend':
        instance       => 'frontend',
        listen_address => ':9331',
    }
}
