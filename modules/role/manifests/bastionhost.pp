# bastion host for all users
class role::bastionhost{
    include profile::base::production
    include profile::firewall
    include profile::backup::host

    ensure_packages(['traceroute', 'mosh'])

    backup::set {'home': }

    firewall::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => 3,
        proto => 'tcp',
        port  => 22,
    }
}
