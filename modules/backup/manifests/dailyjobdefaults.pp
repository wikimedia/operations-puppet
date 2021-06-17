define backup::dailyjobdefaults(
    String $pool,
) {
    bacula::director::jobdefaults { "Daily-${pool}":
        when => 'Daily',
        pool => $pool,
    }
}
