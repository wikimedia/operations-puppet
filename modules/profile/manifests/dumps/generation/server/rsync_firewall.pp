# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::server::rsync_firewall(
    Array[Stdlib::Fqdn] $rsync_clients = lookup('profile::dumps::rsync_internal_clients'),
) {
    firewall::service { 'dumps_rsyncd':
        port   => 873,
        proto  => 'tcp',
        srange => $rsync_clients,
    }
}
