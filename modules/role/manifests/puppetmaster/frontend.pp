# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {
    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    include ::standard
    include ::base::firewall

    include ::profile::backup::host

    include ::profile::puppetmaster::frontend

    include ::profile::conftool::client
    include ::profile::conftool::master

    # config-master.wikimedia.org
    include ::profile::configmaster
    include ::profile::discovery::client

    # IPMI management
    include ::profile::ipmi::mgmt
    include ::profile::access_new_install

    interface::add_ip6_mapped { 'main': }
}
