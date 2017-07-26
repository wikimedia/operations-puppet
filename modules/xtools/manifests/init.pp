class xtools(
    $host = 'xtools.wmflabs.org',
) {
    requires_realm('labs')

    require ::xtools::packages
    require ::xtools::code
    class { 'xtools::web':
        host => $host,
    }
}
