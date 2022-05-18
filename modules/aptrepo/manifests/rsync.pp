# SPDX-License-Identifier: Apache-2.0
# sets up rsync of APT repos between 2 servers
# activates rsync for push from the primary to secondary
class aptrepo::rsync (
    $primary_server,
    $secondary_servers,
){
    # only activate rsync/firewall hole on the server that is NOT active
    if $facts['fqdn'] == $primary_server {

        $ensure_ferm = 'absent'
        $ensure_job = 'present'
        $ensure_sync = 'absent'

    } else {

        $ensure_ferm = 'present'
        $ensure_job = 'absent'
        $ensure_sync = 'present'

        include rsync::server
        include aptrepo::rsync

        rsync::server::module { 'install-srv':
            ensure         => $aptrepo::rsync::ensure,
            path           => '/srv',
            read_only      => 'no',
            hosts_allow    => [$primary_server],
            auto_ferm      => true,
            auto_ferm_ipv6 => true,
        }

        rsync::server::module { 'install-home':
            ensure         => $aptrepo::rsync::ensure,
            path           => '/home',
            read_only      => 'no',
            hosts_allow    => [$primary_server],
            auto_ferm      => true,
            auto_ferm_ipv6 => true,
        }
    }

    $secondary_servers.each |String $secondary_server| {
        systemd::timer::job { "rsync-aptrepo-${secondary_server}":
            ensure      => $ensure_job,
            user        => 'root',
            description => 'rsync APT repo data from the primary to a secondary server',
            command     => "/usr/bin/rsync -avp --delete /srv/ rsync://${secondary_server}/install-srv",
            interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '6h'},
        }
    }
}
