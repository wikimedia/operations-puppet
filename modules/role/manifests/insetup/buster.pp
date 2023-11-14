# SPDX-License-Identifier: Apache-2.0
class role::insetup::buster {
    system::role { 'insetup::buster':
        ensure      => 'present',
        description => 'Host being setup with Debian Buster/Puppet5',
    }

    include profile::base::production
    include profile::firewall
}
