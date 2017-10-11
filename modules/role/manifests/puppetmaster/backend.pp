# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::backend {
    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    include ::standard
    include ::profile::base::firewall

    include ::profile::puppetmaster::backend

    require ::profile::conftool::client
}
