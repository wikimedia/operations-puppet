# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::backend {
    include profile::base::production
    include profile::firewall

    include profile::puppetmaster::backend
    include profile::puppetmaster::production

    require profile::conftool::client
    # This profile is needed for puppet to access state stored in etcd
    require profile::conftool::state

}
