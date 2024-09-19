# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {
    include profile::base::production
    include profile::firewall

    include profile::backup::host

    include profile::puppetmaster::frontend
    include profile::puppetmaster::production

    include profile::conftool::client
    include profile::conftool::master
    include profile::conftool::requestctl_client
    # This profile is needed for puppet to access state stored in etcd
    require profile::conftool::state

    # config-master.wikimedia.org
    include profile::discovery::client

    # IPMI management
    include profile::ipmi::mgmt
    include profile::access_new_install

    # Installs a script to update the netboot images in volatile with firmware
    include profile::puppetmaster::updatenetboot

    # Cergen is Java-based
    include profile::java
}
