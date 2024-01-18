# SPDX-License-Identifier: Apache-2.0
class role::insetup::collaboration_services {
    system::role { 'insetup::collaboration_services':
        ensure      => 'present',
        description => 'Host being setup by Collaboration Services SREs',
    }

    include profile::base::production
    include profile::firewall
    # temp test, will be reverted asap
    include profile::phabricator::reposync
}
