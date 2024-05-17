# For hosts that are dedicated to monitoring database backups
# SPDX-License-Identifier: Apache-2.0
class role::dbbackups::monitoring {
    include profile::firewall
    include profile::base::production

    include profile::mariadb::wmfmariadbpy
    include profile::dbbackups::check
    include profile::dbbackups::dashboard
}
