class role::labs::tools::mailrelay {
    system::role { 'role::labs::tools::mailrelay': description => 'Tool Labs mail relay' }

    include toollabs::mailrelay
}
