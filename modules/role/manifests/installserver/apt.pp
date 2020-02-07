# Sets up a DHCP, TFTP and webproxy and an APT repo
class role::installserver::apt {
    system::role { 'installserver-and-apt-repo': }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host

    include ::profile::installserver::tftp
    include ::profile::installserver::dhcp
    include ::profile::installserver::http
    include ::profile::installserver::proxy
    include ::profile::installserver::preseed
    include ::profile::aptrepo::wikimedia
}
