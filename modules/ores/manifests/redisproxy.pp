class ores::redisproxy(
    $server,
) {
    host { 'ores-redis':
        ensure => present,
        ip     => ipresolve($server, 4, $::nameservers[0]),
    }
}
