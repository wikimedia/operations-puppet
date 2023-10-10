# SPDX-License-Identifier: Apache-2.0
# @summary sets up rsync of APT repos between 2 servers
#          activates rsync for push from the primary to secondary
# @param primary_server the active server data will be pusshed from this server to the secondaries
# @param secondary_servers the passive servers. Firewall rules and rsync will
#        be configured to receive data
class aptrepo::rsync (
    Stdlib::Fqdn        $primary_server,
    Array[Stdlib::Fqdn] $secondary_servers,
){
    $ensure_sync = ($facts['fqdn'] == $primary_server).bool2str('absent', 'present')

    unless $secondary_servers.empty() {

        rsync::server::module { 'install-srv':
            ensure         => $ensure_sync,
            path           => '/srv',
            read_only      => 'no',
            hosts_allow    => [$primary_server],
            auto_ferm      => true,
            auto_ferm_ipv6 => true,
        }

        rsync::server::module { 'install-home':
            ensure         => $ensure_sync,
            path           => '/home',
            read_only      => 'no',
            hosts_allow    => [$primary_server],
            auto_ferm      => true,
            auto_ferm_ipv6 => true,
        }

        ($secondary_servers + $primary_server).each |String $server| {
            $ensure_job = ($primary_server == $facts['networking']['fqdn'] and $primary_server != $server).bool2str('present', 'absent')
            systemd::timer::job { "rsync-aptrepo-${server}":
                ensure      => $ensure_job,
                user        => 'root',
                description => 'rsync APT repo data from the primary to a secondary server',
                command     => "/usr/bin/rsync -avp --delete /srv/ rsync://${server}/install-srv",
                interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '6h'},
            }
        }
    }
}
