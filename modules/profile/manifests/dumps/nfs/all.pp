class profile::dumps::web::nfs::generation(
    $clients_all = hiera('dumps_nfs_clients'),
) {
    $clients         = array_concat($clients_all['snapshots'], $clients_all['other'])
    $mountd_port     = '32767'
    $statd_port      = '32765'
    $statd_out       = '32766'
    $portmapper_port = '111'
    $lockd_udp       = '32768'
    $lockd_tcp       = '32769'
    $path             = '/data'

    class { '::dumps::nfs':
        clients     => $clients,
        statd_port  => $statd_port,
        statd_out   => $statd_out,
        lockd_udp   => $lockd_udp,
        lockd_tcp   => $lockd_tcp,
        mountd_port => $mountd_port,
        path        => $path,
    }
}
