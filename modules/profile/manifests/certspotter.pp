# SPDX-License-Identifier: Apache-2.0
# = Class: profile::certspotter
#
# Sets up certspotter for Wikimedia prod.

class profile::certspotter (
    String              $alert_email     = lookup('profile::certspotter::alert_email'),
    Array[Stdlib::Fqdn] $monitor_domains = lookup('profile::certspotter::monitor_domains'),
) {

    class { 'certspotter':
        alert_email     => $alert_email,
        monitor_domains => $monitor_domains,
    }

}
