# SPDX-License-Identifier: Apache-2.0
class role::insetup::collaboration_services::gerrit {
    include profile::base::production
    include profile::firewall
    include profile::java
}
