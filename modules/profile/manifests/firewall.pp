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
# @param defs_from_etcd_nft build ferm definitions from requestctl etcd data for nftables (temporary)
class profile::firewall (
    String                     $conftool_prefix             = lookup('conftool_prefix'),
    Array[Stdlib::IP::Address] $monitoring_hosts            = lookup('monitoring_hosts'),
    Array[Stdlib::IP::Address] $cumin_masters               = lookup('cumin_masters'),
    Array[Stdlib::IP::Address] $bastion_hosts               = lookup('bastion_hosts'),
    Array[Stdlib::IP::Address] $cache_hosts                 = lookup('cache_hosts'),
    Array[Stdlib::IP::Address] $kafka_brokers_main          = lookup('kafka_brokers_main'),
    Array[Stdlib::IP::Address] $kafka_brokers_jumbo         = lookup('kafka_brokers_jumbo'),
    Array[Stdlib::IP::Address] $kafka_brokers_logging       = lookup('kafka_brokers_logging'),
    Array[Stdlib::IP::Address] $kafkamon_hosts              = lookup('kafkamon_hosts'),
    Array[Stdlib::IP::Address] $zookeeper_hosts_main        = lookup('zookeeper_hosts_main'),
    Array[Stdlib::IP::Address] $zookeeper_flink_hosts       = lookup('zookeeper_flink_hosts'),
    Array[Stdlib::IP::Address] $druid_public_hosts          = lookup('druid_public_hosts'),
    Array[Stdlib::IP::Address] $labstore_hosts              = lookup('labstore_hosts'),
    Array[Stdlib::IP::Address] $mysql_root_clients          = lookup('mysql_root_clients'),
    Array[Stdlib::IP::Address] $deployment_hosts            = lookup('deployment_hosts'),
    Array[Stdlib::Host]        $prometheus_nodes            = lookup('prometheus_nodes'),
    Firewall::Provider         $provider                    = lookup('profile::firewall::provider'),
    Boolean                    $manage_nf_conntrack         = lookup('profile::firewall::manage_nf_conntrack'),
    Boolean                    $enable_logging              = lookup('profile::firewall::enable_logging'),
    Boolean                    $defs_from_etcd              = lookup('profile::firewall::defs_from_etcd'),
    Boolean                    $defs_from_etcd_nft          = lookup('profile::firewall::defs_from_etcd_nft'),
    Integer                    $ferm_icinga_retry_interval  = lookup('profile::firewall::ferm_icinga_retry_interval'),
    Stdlib::Unixpath           $ferm_status_script          = lookup('profile::firewall::ferm_status_script'),
) {
    include network::constants
    class { 'firewall':
        provider           => $provider,
        ferm_status_script => $ferm_status_script,
    }

    if $enable_logging and $provider == 'ferm' {
        include profile::firewall::log::ferm
    }

    if $manage_nf_conntrack and !$facts['wmflib']['is_container'] {
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
    }

    firewall::service { 'ssh-from-bastion':
        proto  => 'tcp',
        port   => 22,
        srange => $bastion_hosts,
    }

    firewall::service { 'ssh-from-cumin-masters':
        proto    => 'tcp',
        port     => 22,
        src_sets => ['CUMIN_MASTERS'],
    }

    $all_monitoring_hosts = $prometheus_nodes + $monitoring_hosts
    unless $all_monitoring_hosts.empty() {
        ['udp', 'tcp'].each |$proto| {
            firewall::service { "full-monitoring-metrics-access-${proto}":
                proto      => $proto,
                port_range => [1,65535],
                srange     => $all_monitoring_hosts,
            }
        }
    }

    ensure_packages('conntrack')

    if $defs_from_etcd {
        confd::file { '/etc/ferm/conf.d/00_defs_requestctl':
            ensure          => stdlib::ensure($provider == 'ferm'),
            reload          => '/bin/systemctl reload ferm',
            watch_keys      => ['/request-ipblocks/abuse'],
            content         => file('profile/firewall/defs_requestctl.tpl'),
            prefix          => $conftool_prefix,
            relative_prefix => false,
        }
    }

    case $provider {
        'ferm': {
            if $defs_from_etcd {
                # unmanaged files under /etc/ferm/conf.d are purged
                # so we define the file to stop it being deleted
                file { '/etc/ferm/conf.d/00_defs_requestctl':
                    ensure => file,
                }
                ferm::rule { 'drop-blocked-nets':
                    prio => '01',
                    rule => 'saddr $BLOCKED_NETS DROP;',
                    desc => 'drop abuse/blocked_nets.yaml defined in the requestctl private repo',
                }
            }
            ferm::conf { 'main':
                prio   => '02',
                source => 'puppet:///modules/base/firewall/main-input-default-drop.conf',
            }

            # Set all DSCP to default marking - for granular classification use nftables
            ferm::rule { 'dscp-default':
                prio  => 99,
                table => 'mangle',
                chain => 'POSTROUTING',
                rule  => 'DSCP set-dscp-class CS0;',
            }

            ferm::conf { 'defs':
                prio    => '00',
                content => template('base/firewall/defs.erb'),
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
                retry_interval => $ferm_icinga_retry_interval,
            }
        }

        'nftables': {
            include profile::firewall::nftables_base_sets

            # The following priorities apply:
            # < 100 - Anything which should precede the base firewall
            # 100   - The base firewall definition
            # > 100 - Freely available for changes which come after the base setup
            nftables::file { 'base':
                order   => 100,
                content => file('profile/firewall/base.nft'),
            }

            if $defs_from_etcd and $defs_from_etcd_nft {
                confd::file { '/etc/nftables/sets/requestctl.nft':
                    reload          => '/bin/systemctl reload nftables',
                    watch_keys      => ['/request-ipblocks/abuse'],
                    content         => file('profile/firewall/defs_requestctl_nftables.tpl'),
                    prefix          => $conftool_prefix,
                    relative_prefix => false,
                }

                # unmanaged files under /etc/nftables/sets are purged
                # so we define the file to stop it being deleted
                file { '/etc/nftables/sets/requestctl.nft':
                    ensure => file,
                }

                nftables::file::input { 'drop-blocked-nets':
                    order   => 5,
                    content => 'ip saddr $BLOCKED_NETS drop',
                }
            }

            prometheus::node_textfile { 'check-nft':
                filesource => 'puppet:///modules/profile/firewall/check_nftables.py',
                interval   => '*:0/30',
                run_cmd    => '/usr/local/bin/check-nft',
            }
        }

        default: { fail("unknown provider: ${provider}") }
    }
}
