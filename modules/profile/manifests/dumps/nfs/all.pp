class profile::dumps::nfs::all(
    $clients_all = hiera('dumps_nfs_clients'),
) {
    require ::profile::dumps::nfs::ferm

    $path    = '/data'
    $clients = {'generation' => pick($clients_all['snapshots'], []),
                'public'     => pick($clients_all['other'], [])}

    class { '::dumps::nfs':
        clients => $clients,
        path    => $path,
    }
}
