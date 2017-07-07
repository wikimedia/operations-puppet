# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::backend {
    include ::standard
    include ::base::firewall

    include ::profile::pupetmaster::backend

    require ::profile::conftool::client
}
