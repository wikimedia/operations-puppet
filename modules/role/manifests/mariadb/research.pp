# SPDX-License-Identifier: Apache-2.0

class role::mariadb::research {
    include profile::base::production
    include profile::firewall
}
