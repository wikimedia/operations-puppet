# Same for weekly backups
define backup::weeklyschedule(
    String $day,
) {
    bacula::director::schedule { "Weekly-${day}":
        # lint:ignore:arrow_alignment
        runs => [
            { 'level' => 'Full',
              'at'    => "${day} at 02:05",
            },
                ],
        # lint:endignore
    }
}
