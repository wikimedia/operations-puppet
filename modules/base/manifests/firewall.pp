# Don't include this sub class on all hosts yet
# NOTE: Policy is DROP by default
class base::firewall (
    Array[Stdlib::IP::Address] $monitoring_hosts        = [],
    Array[Stdlib::IP::Address] $cumin_masters           = [],
    Array[Stdlib::IP::Address] $bastion_hosts           = [],
    Array[Stdlib::IP::Address] $cache_hosts             = [],
    Array[Stdlib::IP::Address] $kafka_brokers_main      = [],
    Array[Stdlib::IP::Address] $kafka_brokers_analytics = [],
    Array[Stdlib::IP::Address] $kafka_brokers_jumbo     = [],
    Array[Stdlib::IP::Address] $kafka_brokers_logging   = [],
    Array[Stdlib::IP::Address] $zookeeper_hosts_main    = [],
    Array[Stdlib::IP::Address] $druid_public_hosts      = [],
    Array[Stdlib::IP::Address] $labstore_hosts          = [],
    Array[Stdlib::IP::Address] $mysql_root_clients      = [],
    Array[Stdlib::IP::Address] $deployment_hosts        = [],
    Array[Stdlib::Host]        $prometheus_hosts        = [],
    Boolean                    $block_abuse_nets        = false,
    Boolean                    $default_reject          = false,
) {
    include network::constants
    include ferm

    ferm::conf { 'defs':
        prio    => '00',
        content => template('base/firewall/defs.erb'),
    }
    ferm::rule { 'default-reject':
        ensure => $default_reject.bool2str('present', 'absent'),
        prio   => '99',
        rule   => 'REJECT;'
    }

    # Increase the size of conntrack table size (default is 65536)
    sysctl::parameters { 'ferm_conntrack':
        values => {
            'net.netfilter.nf_conntrack_max'                   => 262144,
            'net.netfilter.nf_conntrack_tcp_timeout_time_wait' => 65,
        },
    }

    # The sysctl value net.netfilter.nf_conntrack_buckets is read-only. It is configured
    # via a modprobe parameter, bump it manually for running systems
    exec { 'bump nf_conntrack hash table size':
        command => '/bin/echo 32768 > /sys/module/nf_conntrack/parameters/hashsize',
        onlyif  => "/bin/grep --invert-match --quiet '^32768$' /sys/module/nf_conntrack/parameters/hashsize",
    }

    if $block_abuse_nets {
        network::parse_abuse_nets('ferm').each |String $net_name, Network::Abuse_net $config| {
            ferm::rule {"drop-abuse-net-${net_name}":
                prio => '01',
                rule => "saddr (${config['networks'].join(' ')}) DROP;",
            }
        }
    }
    ferm::conf { 'main':
        prio   => '02',
        source => 'puppet:///modules/base/firewall/main-input-default-drop.conf',
    }

    $bastion_hosts_str = join($bastion_hosts, ' ')
    ferm::rule { 'bastion-ssh':
        rule   => "proto tcp dport ssh saddr (${bastion_hosts_str}) ACCEPT;",
    }

    if !empty($monitoring_hosts) {
        $monitoring_hosts_str = join($monitoring_hosts, ' ')
        ferm::rule { 'monitoring-all':
            rule   => "saddr (${monitoring_hosts_str}) ACCEPT;",
        }
    }

    ferm::rule { 'prometheus-all':
        rule   => "saddr @resolve((${prometheus_hosts.join(' ')})) ACCEPT;",
    }

    ferm::service { 'ssh-from-cumin-masters':
        proto  => 'tcp',
        port   => '22',
        srange => '$CUMIN_MASTERS',
    }

    # TODO: remove after a puppet cycle
    file { '/usr/lib/nagios/plugins/check_conntrack':
        ensure => absent,
    }

    nrpe::plugin { 'check_conntrack':
        source => 'puppet:///modules/base/firewall/check_conntrack.py',
    }

    nrpe::monitor_service { 'conntrack_table_size':
        description   => 'Check size of conntrack table',
        nrpe_command  => '/usr/local/lib/nagios/plugins/check_conntrack 80 90',
        contact_group => 'admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_conntrack',
    }

    sudo::user { 'nagios_check_ferm':
        ensure => absent,
    }

    nrpe::plugin { 'check_ferm':
        source => 'puppet:///modules/base/firewall/check_ferm',
    }

    # TODO: remove after a puppet cycle
    file { '/usr/lib/nagios/plugins/check_ferm':
        ensure => absent,
    }

    nrpe::monitor_service { 'ferm_active':
        description    => 'Check whether ferm is active by checking the default input chain',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_ferm',
        sudo_user      => 'root',
        contact_group  => 'admins',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_ferm',
        check_interval => 30,
    }
}
