class role::wmcs::novaproxy {
    system::role { $name: }

    include ::profile::firewall
    include ::profile::wmcs::novaproxy
}
