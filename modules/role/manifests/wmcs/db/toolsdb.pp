# SPDX-License-Identifier: Apache-2.0
class role::wmcs::db::toolsdb {
    system::role { $name: }

    include ::profile::mariadb::monitor
    include ::profile::wmcs::services::toolsdb
}
