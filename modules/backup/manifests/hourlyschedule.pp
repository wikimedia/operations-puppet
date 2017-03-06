# Same for hourly backups
define backup::hourlyschedule($pool) {
    bacula::director::schedule { "Hourly-${name}":
        # lint:ignore:arrow_alignment
        runs => [
            { 'level' => 'Full',
              'at'    => "${name} at 02:05",
            },
            { 'level' => 'Incremental',
              'at'    => "${name} hourly",
            },
                ],
        # lint:endignore
    }

    bacula::director::jobdefaults { "Hourly-${name}-${pool}":
        when => "Hourly-${name}",
        pool => $pool,
    }
}
