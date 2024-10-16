# SPDX-License-Identifier: Apache-2.0
# @summary cloud vps per-project puppetserver
class role::puppetserver::cloud_vps_project {
    include profile::puppetserver::wmcs
    include profile::puppetserver::scripts
    include profile::openstack::base::puppetmaster::stale_certs_exporter
}
