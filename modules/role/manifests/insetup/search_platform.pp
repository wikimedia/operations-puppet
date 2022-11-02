# SPDX-License-Identifier: Apache-2.0
class role::insetup::search_platform {
    system::role { 'insetup::search_platform':
        ensure      => 'present',
        description => 'Host being setup by Search Platform SREs',
    }

    include profile::base::production
    include profile::base::firewall
}
