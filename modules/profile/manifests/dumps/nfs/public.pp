class profile::dumps::nfs::public(
    $clients_all = hiera('dumps_nfs_clients'),
) {
    require ::profile::dump::nfs::ferm

    $path    = '/data'
    $clients = {'public' => pick($clients_all['other'], [])}

    class { '::dumps::nfs':
        clients => $clients,
        path    => $path,
    }
}
