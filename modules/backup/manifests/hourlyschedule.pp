# Same for hourly backups
define backup::hourlyschedule(
    String $day,
) {
    bacula::director::schedule { "Hourly-${day}":
        # lint:ignore:arrow_alignment
        runs => [
            { 'level' => 'Full',
              'at'    => "${day} at 02:05",
            },
            { 'level' => 'Incremental',
              'at'    => 'hourly',
            },
                ],
        # lint:endignore
    }
}
