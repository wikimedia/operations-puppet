# Utility definition used internally to deduplicate code
define backup::schedule($pool) {
    bacula::director::schedule { "Monthly-1st-${name}":
        runs => [
            { 'level' => 'Full',
              'at'    => "1st ${name} at 02:05",
            },
            { 'level' => 'Differential',
              'at'    => "3rd ${name} at 03:05",
            },
            { 'level' => 'Incremental',
              'at'    => 'at 04:05',
            },
        ],
    }

    bacula::director::jobdefaults { "Monthly-1st-${name}-${pool}":
        when => "Monthly-1st-${name}",
        pool => $pool,
    }
}
