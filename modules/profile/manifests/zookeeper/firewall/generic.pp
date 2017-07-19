# == Class profile::zookeeper::firewall::generic
#
# Generic firewall rules for a zookeeper cluster
#
class profile::zookeeper::firewall::generic {

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => '$DOMAIN_NETWORKS',
    }
}