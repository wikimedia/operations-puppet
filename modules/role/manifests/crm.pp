# SPDX-License-Identifier: Apache-2.0
# Community crm infrastructure
class role::crm {
    system::role { 'crm': description => 'Community CRM' }

    include profile::base::production
    include profile::firewall
    include profile::community_civicrm
    include profile::prometheus::apache_exporter

    if $::realm == 'production' {
        include profile::tlsproxy::envoy
    }
}
