# Same for weekly backups
define backup::weeklyschedule($pool) {
    bacula::director::schedule { "Weekly-${name}":
        runs => [
            { 'level' => 'Full',
              'at'    => "${name} at 02:05",
            },
                ],
    }

    bacula::director::jobdefaults { "Weekly-${name}-${pool}":
        when => "Weekly-${name}",
        pool => $pool,
    }
}
