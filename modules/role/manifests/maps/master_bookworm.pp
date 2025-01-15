# SPDX-License-Identifier: Apache-2.0
# Sets up a maps server master
class role::maps::master_bookworm {
    include profile::base::production
    include profile::firewall
    include profile::maps::osm_master
    include profile::prometheus::postgres_exporter
}
