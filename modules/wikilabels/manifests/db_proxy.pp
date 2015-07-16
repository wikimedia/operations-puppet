class wikilabels::db_proxy(
    $server,
) {
    host { 'wikilabels-database':
        ensure => present,
        ip     => ipresolve($server, 4, $::nameservers[0]),
    }
}