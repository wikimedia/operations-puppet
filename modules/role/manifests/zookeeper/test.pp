class role::zookeeper::test {
    system::role { 'role::zookeeper::test':
        description => 'Zookeeper test node'
    }
    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::zookeeper::server
    include ::profile::zookeeper::firewall
}
