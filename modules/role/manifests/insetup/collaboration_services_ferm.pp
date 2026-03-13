# SPDX-License-Identifier: Apache-2.0
class role::insetup::collaboration_services_ferm {
    include profile::base::production
    include profile::firewall
    include profile::base::reboot_unattended
}
