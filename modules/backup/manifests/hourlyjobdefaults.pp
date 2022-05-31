# SPDX-License-Identifier: Apache-2.0
define backup::hourlyjobdefaults(
    String $pool,
    String $day,
) {
    bacula::director::jobdefaults { "Hourly-${day}-${pool}":
        when => "Hourly-${day}",
        pool => $pool,
    }
}
