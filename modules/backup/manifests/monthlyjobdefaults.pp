# SPDX-License-Identifier: Apache-2.0
# Defaults depend on both the day and the pool
define backup::monthlyjobdefaults(
    String $pool,
    String $day,
) {

    bacula::director::jobdefaults { "Monthly-1st-${day}-${pool}":
        when => "Monthly-1st-${day}",
        pool => $pool,
    }
}
