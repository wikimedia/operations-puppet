# Same for weekly backups
define backup::weeklyschedule($pool) {
    bacula::director::schedule { "Weekly-${name}":
        # lint:ignore:arrow_alignment
        runs => [
            { 'level' => 'Full',
              'at'    => "${name} at 02:05",
            },
                ],
        # lint:endignore
    }

    bacula::director::jobdefaults { "Weekly-${name}-${pool}":
        when => "Weekly-${name}",
        pool => $pool,
    }
}
