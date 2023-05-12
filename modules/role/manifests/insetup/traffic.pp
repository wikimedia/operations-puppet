# SPDX-License-Identifier: Apache-2.0
class role::insetup::traffic {
    system::role { 'insetup::traffic':
        ensure      => 'present',
        description => 'Host being setup by Traffic SREs',
    }

    include profile::base::production

    if $facts['networking']['fqdn'] =~ /^lvs[\d]{4}/ {
        # If we are an LVS host, bring in the LVS kernel config to get iptables
        # blacklisted in modprobe, and use the no_firwall base, so that it's
        # compatible with re-roling straight into lvs::balancer.  See also
        # T336428.
        include ::profile::base::no_firewall
        include lvs::kernel_config  # lint:ignore:wmf_styleguide
    } else {
        # Otherwise, do it the normal way
        include profile::base::firewall
    }
}
