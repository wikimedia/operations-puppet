# == Class profile::zookeeper::firewall::druid
#
# Firewall rules for the druid cluster in eqiad
#
class profile::zookeeper::firewall::druid {

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => '$DRUID_HOSTS',
    }
}