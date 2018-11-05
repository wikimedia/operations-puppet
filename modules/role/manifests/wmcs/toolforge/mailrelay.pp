class role::wmcs::toolforge::mailrelay {
    system::role { $name: }

    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::mailrelay
}
