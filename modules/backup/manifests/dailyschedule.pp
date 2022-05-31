# SPDX-License-Identifier: Apache-2.0
# Same for daily backups
define backup::dailyschedule() {
    bacula::director::schedule { 'Daily':
        runs => [
            { 'level' => 'Full',
              'at'    => 'daily at 04:05',
            },
                ],
    }
}
