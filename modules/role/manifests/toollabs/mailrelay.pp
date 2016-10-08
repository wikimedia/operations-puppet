class role::toollabs::mailrelay {
    system::role { 'role::toollabs::mailrelay': description => 'Tool Labs mail relay' }

    include ::toollabs::mailrelay
}
