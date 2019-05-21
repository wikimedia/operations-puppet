# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {
    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log

    include ::profile::backup::host

    include ::profile::puppetmaster::frontend

    include ::profile::conftool::client
    include ::profile::conftool::master
    # This profile is needed for puppet to access state stored in etcd
    require ::profile::conftool::state

    # config-master.wikimedia.org
    include ::profile::configmaster
    include ::profile::discovery::client

    # IPMI management
    include ::profile::ipmi::mgmt
    include ::profile::access_new_install

    # Installs a script to update the netboot images in volatile with firmware
    include ::profile::puppetmaster::updatenetboot

    interface::add_ip6_mapped { 'main': }
}
