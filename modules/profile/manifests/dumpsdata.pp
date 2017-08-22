class profile::dumpsdata(
    $clients = hiera('dumps_clients_snapshots'),
) {
    class { '::dumpsnfs':
        clients => $clients,
    }
}
