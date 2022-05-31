# SPDX-License-Identifier: Apache-2.0
# Same for weekly backups
define backup::weeklyjobdefaults(
    String $pool,
    String $day,
) {
    bacula::director::jobdefaults { "Weekly-${day}-${pool}":
        when => "Weekly-${day}",
        pool => $pool,
    }
}
