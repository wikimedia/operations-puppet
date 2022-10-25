# SPDX-License-Identifier: Apache-2.0
class role::wikilabels::db {
    system::role { $name: }

    include ::profile::base::production
    include ::profile::wikilabels::db
}
