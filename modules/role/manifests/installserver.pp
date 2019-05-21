class role::installserver {
    system::role { 'installserver': }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::backup::host

    include ::profile::installserver::tftp
    include ::profile::installserver::dhcp
    include ::profile::installserver::http
    include ::profile::installserver::proxy
    include ::profile::installserver::preseed
    include ::profile::aptrepo::wikimedia

    interface::add_ip6_mapped { 'main': }

}
