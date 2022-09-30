# SPDX-License-Identifier: Apache-2.0
class profile::dns::auth::monitoring {
    include ::network::constants
    include ::profile::base::firewall

    # Metrics!
    class { 'prometheus::node_gdnsd': }

    # Monitor gdnsd checkconf via NRPE
    class { 'gdnsd::monitor_conf': }

    # This monitors the specific authdns server directly via
    #  its own fqdn, which won't generally be one of the listener
    #  addresses we really care about.  This gives a more-direct
    #  view of reality, though, as the mapping of listener addresses
    #  to real hosts could be fluid due to routing/anycast.
    monitoring::service { 'auth dns':
        description   => 'Auth DNS',
        check_command => 'check_dns_query_auth_port!5353!www.wikipedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/DNS',
    }

    # port 5353 monitoring listeners (which humans and other tools may hit!)
    ferm::service { 'udp_dns_auth_monitor':
        proto   => 'udp',
        notrack => true,
        port    => '5353',
        srange  => "(${network::constants::aggregate_networks.join(' ')})",
    }
    ferm::service { 'tcp_dns_auth_monitor':
        proto   => 'tcp',
        notrack => true,
        port    => '5353',
        srange  => "(${network::constants::aggregate_networks.join(' ')})",
    }

    # ensure exactly one copy of the daemon is running (there may be rare bugs
    # that cause old copies of the daemon to linger, in which case we want to
    # investigate them)
    nrpe::monitor_service { 'gdnsd_proc':
        description   => 'gdnsd daemon runs exactly once',
        contact_group => 'admins',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gdnsd -a /usr/sbin/gdnsd',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/DNS',
    }
}
