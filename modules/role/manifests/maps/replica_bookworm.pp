# SPDX-License-Identifier: Apache-2.0
# Sets up a maps server replica
class role::maps::replica_bookworm {
    include profile::base::production
    include profile::firewall
    include profile::maps::osm_replica
    include profile::prometheus::postgres_exporter
}
