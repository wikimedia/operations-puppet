# Temporary solution until someone has input about what to do with base::firewall
class profile::base::firewall (
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
    Array[Stdlib::IP::Address] $hadoop_masters          = lookup('hadoop_masters',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $druid_public_hosts      = lookup('druid_public_hosts',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $mysql_root_clients      = lookup('mysql_root_clients',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $deployment_hosts        = lookup('deployment_hosts',
                                                                {default_value => []}),
    Boolean                    $enable_logging  = lookup('profile::base::firewall::enable_logging')
) {
    class { '::base::firewall':
        monitoring_hosts        => $monitoring_hosts,
        cumin_masters           => $cumin_masters,
        bastion_hosts           => $bastion_hosts,
        cache_hosts             => $cache_hosts,
        kafka_brokers_main      => $kafka_brokers_main,
        kafka_brokers_analytics => $kafka_brokers_analytics,
        kafka_brokers_jumbo     => $kafka_brokers_jumbo,
        kafka_brokers_logging   => $kafka_brokers_logging,
        zookeeper_hosts_main    => $zookeeper_hosts_main,
        hadoop_masters          => $hadoop_masters,
        druid_public_hosts      => $druid_public_hosts,
        mysql_root_clients      => $mysql_root_clients,
        deployment_hosts        => $deployment_hosts,
    }
    if $enable_logging {
        include profile::base::firewall::log
    }
}
