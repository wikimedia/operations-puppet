# SPDX-License-Identifier: Apache-2.0
# Temporary solution until someone has input about what to do with base::firewall
# @param conftool_prefix the prfix used for conftool
# @param defs_from_etcd build ferm definitions from requestctl etcd data
class profile::base::firewall (
    String                     $conftool_prefix         = lookup('conftool_prefix'),
    Array[Stdlib::IP::Address] $monitoring_hosts        = lookup('monitoring_hosts',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $cumin_masters           = lookup('cumin_masters',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $bastion_hosts           = lookup('bastion_hosts',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $cache_hosts             = lookup('cache_hosts',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $kafka_brokers_main      = lookup('kafka_brokers_main',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $kafka_brokers_analytics = lookup('kafka_brokers_analytics',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $kafka_brokers_jumbo     = lookup('kafka_brokers_jumbo',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $kafka_brokers_logging   = lookup('kafka_brokers_logging',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $zookeeper_hosts_main    = lookup('zookeeper_hosts_main',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $druid_public_hosts      = lookup('druid_public_hosts',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $labstore_hosts          = lookup('labstore_hosts',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $mysql_root_clients      = lookup('mysql_root_clients',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $deployment_hosts        = lookup('deployment_hosts',
                                                                {default_value => []}),
    Array[Stdlib::Host]        $prometheus_nodes        = lookup('prometheus_nodes',
                                                                {default_value => []}),
    Boolean                    $enable_logging   = lookup('profile::base::firewall::enable_logging'),
    Boolean                    $block_abuse_nets = lookup('profile::base::firewall::block_abuse_nets'),
    Boolean                    $default_reject   = lookup('profile::base::firewall::default_reject'),
    Boolean                    $defs_from_etcd   = lookup('profile::base::firewall::defs_from_etcd'),
) {
    # we should use defs_from_etcd or block_abuse_nets
    $_block_abuse_nets = !$defs_from_etcd and $block_abuse_nets
    class { 'base::firewall':
        monitoring_hosts        => $monitoring_hosts,
        cumin_masters           => $cumin_masters,
        bastion_hosts           => $bastion_hosts,
        cache_hosts             => $cache_hosts,
        kafka_brokers_main      => $kafka_brokers_main,
        kafka_brokers_analytics => $kafka_brokers_analytics,
        kafka_brokers_jumbo     => $kafka_brokers_jumbo,
        kafka_brokers_logging   => $kafka_brokers_logging,
        zookeeper_hosts_main    => $zookeeper_hosts_main,
        druid_public_hosts      => $druid_public_hosts,
        labstore_hosts          => $labstore_hosts,
        mysql_root_clients      => $mysql_root_clients,
        deployment_hosts        => $deployment_hosts,
        prometheus_hosts        => $prometheus_nodes,
        block_abuse_nets        => $_block_abuse_nets,
        default_reject          => $default_reject,
    }
    if $defs_from_etcd {
        # unmanaged files under /etc/ferm/conf.d are purged
        # so we define the file to stop it being deleted
        file { '/etc/ferm/conf.d/00_defs_requestctl':
            ensure => 'file',
        }
        confd::file { '/etc/ferm/conf.d/00_defs_requestctl':
            ensure     => 'present',
            reload     => '/bin/systemctl reload ferm',
            watch_keys => ['/request-ipblocks/abuse'],
            content    => file('profile/firewall/defs_requestctl.tpl'),
            prefix     => $conftool_prefix,
        }
        ferm::rule { 'drop-blocked-nets':
            prio => '01',
            rule => 'saddr $BLOCKED_NETS DROP;',
            desc => 'drop abuse/blocked_nets.yaml defined in the requestctl private repo',
        }
    }
    if $enable_logging {
        include profile::base::firewall::log
    }
}
