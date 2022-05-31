# SPDX-License-Identifier: Apache-2.0
# Utility definition used internally to deduplicate code
define backup::monthlyschedule(
    String $day,
) {
    bacula::director::schedule { "Monthly-1st-${day}":
        runs => [
            { 'level' => 'Full',
              'at'    => "1st ${day} at 02:05",
            },
            { 'level' => 'Differential',
              'at'    => "3rd ${day} at 03:05",
            },
            { 'level' => 'Incremental',
              'at'    => 'at 04:05',
            },
        ],
    }
}
