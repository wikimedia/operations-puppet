# Sets up a DHCP, TFTP and webproxy. No HTTP and APT repo.
class role::installserver::light {
    system::role { 'installserver-without-apt-repo': }

    include profile::standard
    include profile::base::firewall
    include profile::base::cuminunpriv
    include profile::backup::host

    include profile::nginx
    include profile::installserver::tftp
    include profile::installserver::dhcp
    include profile::installserver::proxy
    include profile::installserver::http_light
    include profile::prometheus::squid_exporter
}
