class profile::dumps::nfs::generation(
    $clients_all = hiera('dumps_nfs_clients'),
) {
    require ::profile::dumps::nfs::ferm

    $path    = '/data'
    $clients = {'generation' => pick($clients_all['snapshots'], [])}

    class { '::dumps::nfs':
        clients => $clients,
        path    => $path,
    }
}
