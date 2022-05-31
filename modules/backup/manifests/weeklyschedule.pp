# SPDX-License-Identifier: Apache-2.0
# Same for weekly backups
define backup::weeklyschedule(
    String $day,
) {
    bacula::director::schedule { "Weekly-${day}":
        runs => [
            { 'level' => 'Full',
              'at'    => "${day} at 02:05",
            },
                ],
    }
}
