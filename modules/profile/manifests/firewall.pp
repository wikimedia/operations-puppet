# SPDX-License-Identifier: Apache-2.0
# @param conftool_prefix the prefix used for conftool
# @param monitoring_hosts monitoring hosts
# @param cumin_masters management hosts
# @param bastion_hosts bastion hosts
# @param cache_hosts cache hosts
# @param kafka_brokers_main kfaka broker hosts
# @param kafka_brokers_jumbo kfaka broker jumbo hosts
# @param kafka_brokers_logging  kfaka broker logging hosts
# @param kafkamon_hosts kafka monitoring hosts
# @param zookeeper_hosts_main zookeeper hosts
# @param druid_public_hosts druid hosts
# @param labstore_hosts labstore hosts
# @param mysql_root_clients mysql root client hosts
# @param deployment_hosts deployment hosts
# @param prometheus_nodes prometheus hosts
# @param manage_nf_conntrack manage contract
# @param enable_logging enable logging
# @param defs_from_etcd build ferm definitions from requestctl etcd data
class profile::firewall (
    String                     $conftool_prefix         = lookup('conftool_prefix'),
    Array[Stdlib::IP::Address] $monitoring_hosts        = lookup('monitoring_hosts'),
    Array[Stdlib::IP::Address] $cumin_masters           = lookup('cumin_masters'),
    Array[Stdlib::IP::Address] $bastion_hosts           = lookup('bastion_hosts'),
    Array[Stdlib::IP::Address] $cache_hosts             = lookup('cache_hosts'),
    Array[Stdlib::IP::Address] $kafka_brokers_main      = lookup('kafka_brokers_main'),
    Array[Stdlib::IP::Address] $kafka_brokers_jumbo     = lookup('kafka_brokers_jumbo'),
    Array[Stdlib::IP::Address] $kafka_brokers_logging   = lookup('kafka_brokers_logging'),
    Array[Stdlib::IP::Address] $kafkamon_hosts          = lookup('kafkamon_hosts'),
    Array[Stdlib::IP::Address] $zookeeper_hosts_main    = lookup('zookeeper_hosts_main'),
    Array[Stdlib::IP::Address] $zookeeper_flink_hosts    = lookup('zookeeper_flink_hosts'),
    Array[Stdlib::IP::Address] $druid_public_hosts      = lookup('druid_public_hosts'),
    Array[Stdlib::IP::Address] $labstore_hosts          = lookup('labstore_hosts'),
    Array[Stdlib::IP::Address] $mysql_root_clients      = lookup('mysql_root_clients'),
    Array[Stdlib::IP::Address] $deployment_hosts        = lookup('deployment_hosts'),
    Array[Stdlib::Host]        $prometheus_nodes        = lookup('prometheus_nodes'),
    Firewall::Provider         $provider                = lookup('profile::firewall::provider'),
    Boolean                    $manage_nf_conntrack     = lookup('profile::firewall::manage_nf_conntrack'),
    Boolean                    $enable_logging          = lookup('profile::firewall::enable_logging'),
    Boolean                    $defs_from_etcd          = lookup('profile::firewall::defs_from_etcd'),
) {
    include network::constants
    class { 'firewall':
        provider => $provider,
    }

    if !$facts['wmflib']['is_container'] {
        # Increase the size of conntrack table size (default is 65536)
        sysctl::parameters { 'ferm_conntrack':
            values => {
                'net.netfilter.nf_conntrack_max'                   => 262144,
                'net.netfilter.nf_conntrack_tcp_timeout_time_wait' => 65,
            },
        }
    }
    if $defs_from_etcd {
        # unmanaged files under /etc/ferm/conf.d are purged
        # so we define the file to stop it being deleted
        file { '/etc/ferm/conf.d/00_defs_requestctl':
            ensure => 'file',
        }
        confd::file { '/etc/ferm/conf.d/00_defs_requestctl':
            ensure          => 'present',
            reload          => '/bin/systemctl reload ferm',
            watch_keys      => ['/request-ipblocks/abuse'],
            content         => file('profile/firewall/defs_requestctl.tpl'),
            prefix          => $conftool_prefix,
            relative_prefix => false,
        }
        ferm::rule { 'drop-blocked-nets':
            prio => '01',
            rule => 'saddr $BLOCKED_NETS DROP;',
            desc => 'drop abuse/blocked_nets.yaml defined in the requestctl private repo',
        }
    }
    if $enable_logging {
        include profile::firewall::log
    }

    if $manage_nf_conntrack and !$facts['wmflib']['is_container'] {
        # The sysctl value net.netfilter.nf_conntrack_buckets is read-only. It is configured
        # via a modprobe parameter, bump it manually for running systems
        exec { 'bump nf_conntrack hash table size':
            command => '/bin/echo 32768 > /sys/module/nf_conntrack/parameters/hashsize',
            onlyif  => "/bin/grep --invert-match --quiet '^32768$' /sys/module/nf_conntrack/parameters/hashsize",
        }
    }

    ferm::conf { 'defs':
        prio    => '00',
        content => template('base/firewall/defs.erb'),
    }
    ferm::conf { 'main':
        prio   => '02',
        source => 'puppet:///modules/base/firewall/main-input-default-drop.conf',
    }

    ferm::service { 'ssh-from-bastion':
        proto  => 'tcp',
        port   => '22',
        srange => "(${bastion_hosts.join(' ')})",
    }

    ferm::service { 'ssh-from-cumin-masters':
        proto  => 'tcp',
        port   => '22',
        srange => '$CUMIN_MASTERS',
    }

    unless $monitoring_hosts.empty() {
        ferm::rule { 'monitoring-all':
            rule   => "saddr (${monitoring_hosts.join(' ')}) ACCEPT;",
        }
    }

    unless $prometheus_nodes.empty() {
        ferm::rule { 'prometheus-all':
            rule   => "saddr @resolve((${prometheus_nodes.join(' ')})) ACCEPT;",
        }
    }

    case $provider {
        'ferm': {
            nrpe::plugin { 'check_conntrack':
                source => 'puppet:///modules/base/firewall/check_conntrack.py',
            }

            nrpe::monitor_service { 'conntrack_table_size':
                description   => 'Check size of conntrack table',
                nrpe_command  => '/usr/local/lib/nagios/plugins/check_conntrack 80 90',
                contact_group => 'admins',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_conntrack',
            }

            nrpe::plugin { 'check_ferm':
                source => 'puppet:///modules/base/firewall/check_ferm',
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
        default: { fail("unknown provider: ${provider}") }
    }
}
