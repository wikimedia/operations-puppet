# For hosts that are dedicated to monitoring database backups
# SPDX-License-Identifier: Apache-2.0
class role::dbbackups::monitoring {
    system::role { 'dbbackups::monitoring':
        description => 'Database backups monitoring dashboard and metrics endpoint',
    }

    include ::profile::base::firewall
    include ::profile::base::production

    include ::profile::mariadb::wmfmariadbpy
    include ::profile::dbbackups::check
    include ::profile::dbbackups::dashboard
}
