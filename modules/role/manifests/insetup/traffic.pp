# SPDX-License-Identifier: Apache-2.0
class role::insetup::traffic {
    system::role { 'insetup::traffic':
        ensure      => 'present',
        description => 'Host being setup by Traffic SREs',
    }

    include profile::base::production
    include profile::base::firewall
    # If we are an LVS host the install the appropriate sysctls so we can
    # complete reimaging. See T336428
    if $facts['networking']['fqdn'] =~ /^lvs[\d]{4}/ {
        include lvs::kernel_config  # lint:ignore:wmf_styleguide
    }
}
