# SPDX-License-Identifier: Apache-2.0

# Netmon network probes related functions
class profile::netmon::prober {
    class { '::prometheus::blackbox_exporter': }
}
