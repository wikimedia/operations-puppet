# SPDX-License-Identifier: Apache-2.0
# Set up a single node/master staging maps database
class role::maps::staging {
    include profile::base::production
    include profile::firewall
    include profile::maps::osm_master
    include profile::prometheus::postgres_exporter
}
