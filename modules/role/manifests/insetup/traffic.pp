# SPDX-License-Identifier: Apache-2.0
class role::insetup::traffic {
    include profile::base::production
    # If we are an LVS host the install the appropriate sysctls so we can
    # complete reimaging. See T336428
    if $facts['networking']['fqdn'] =~ /^lvs[\d]{4}/ {
        # If we are an LVS host, bring in the LVS kernel config to get iptables
        # blacklisted in modprobe, and use the no_firwall base, so that it's
        # compatible with re-roling straight into lvs::balancer.  See also
        # T336428.
        include ::profile::base::no_firewall
        include lvs::kernel_config  # lint:ignore:wmf_styleguide
    } else {
        include profile::firewall
    }
}
