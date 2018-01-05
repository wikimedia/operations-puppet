class role::installserver {
    system::role { 'installserver': }
    include ::role::installserver::tftp
    include ::role::installserver::dhcp
    include ::role::installserver::http
    include ::role::installserver::proxy
    include ::role::installserver::preseed
    include ::role::aptrepo::wikimedia

    interface::add_ip6_mapped { 'main': }
}
