# == Class profile::zookeeper::firewall::generic
#
# Firewall rules for a zookeeper cluster.
#
class profile::zookeeper::firewall (
    $srange = hiera('profile::zookeeper::firewall::srange'),
) {
    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => $srange,
    }
}