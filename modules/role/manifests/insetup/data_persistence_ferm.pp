# SPDX-License-Identifier: Apache-2.0
class role::insetup::data_persistence_ferm {
    include profile::base::production
    include profile::firewall
}
