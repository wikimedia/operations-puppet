define backup::hourlyjobdefaults(
    String $pool,
    String $day,
) {
    bacula::director::jobdefaults { "Hourly-${day}-${pool}":
        when => "Hourly-${day}",
        pool => $pool,
    }
}
