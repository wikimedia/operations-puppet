# Role classes for ganeti
class role::ganeti {

    system::role { 'ganeti':
        description => 'Ganeti Node',
    }

    include ::standard
    include ::profile::ganeti

    # If ganeti_cluster fact is not defined, the node has not been added to a
    # cluster yet, so don't monitor and don't setup a firewall
    if $::ganeti_cluster {
        include ::profile::base::firewall
        include ::profile::ganeti::firewall
        include ::profile::ganeti::monitoring
    }
}
