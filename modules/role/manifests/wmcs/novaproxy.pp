class role::wmcs::novaproxy {
    system::role { $name: }

    include ::profile::base::firewall
    include ::profile::wmcs::novaproxy
}
