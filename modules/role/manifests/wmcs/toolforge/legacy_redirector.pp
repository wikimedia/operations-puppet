class role::wmcs::toolforge::legacy_redirector {
    system::role { $name: }

    include ::profile::base::firewall
    include ::profile::toolforge::base
    include ::profile::toolforge::infrastructure
    include ::profile::toolforge::legacy_redirector
}
