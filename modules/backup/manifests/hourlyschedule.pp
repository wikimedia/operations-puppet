# SPDX-License-Identifier: Apache-2.0
# Same for hourly backups
define backup::hourlyschedule(
    String $day,
) {
    bacula::director::schedule { "Hourly-${day}":
        runs => [
            { 'level' => 'Full',
              'at'    => "${day} at 02:05",
            },
            { 'level' => 'Incremental',
              'at'    => 'hourly',
            },
                ],
    }
}
