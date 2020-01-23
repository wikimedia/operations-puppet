class role::wmcs::toolforge::elastic {
    system::role { $name: }
    include ::profile::base::firewall
    include ::profile::toolforge::base
    include ::profile::toolforge::apt_pinning
    include ::profile::elasticsearch::toolforge
    include ::profile::toolforge::elasticsearch::nginx
}
