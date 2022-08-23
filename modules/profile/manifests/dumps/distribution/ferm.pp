class profile::dumps::distribution::ferm(
    Array[Stdlib::Fqdn] $internal_rsync_clients = lookup('profile::dumps::rsync_internal_clients'),
    $rsync_mirrors = lookup('profile::dumps::distribution::mirrors'),
) {
    $active_mirrors = $rsync_mirrors.filter |$item| { $item['active'] == 'yes' }
    $mirror_hosts = $active_mirrors.map |$item| { $item['ipv4'] + $item['ipv6'] }

    $rsync_clients = flatten($internal_rsync_clients + $mirror_hosts)

    ferm::service { 'dumps_rsyncd':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients.join(' ')}))",
    }
}
