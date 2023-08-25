# bastion host for all users
class role::bastionhost{
    system::role { 'bastionhost':
        description => 'Bastion host for all shell users',
    }

    include profile::base::production
    include profile::firewall
    include profile::backup::host

    ensure_packages(['mtr-tiny', 'traceroute', 'mosh'])

    backup::set {'home': }

    firewall::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => 3,
        proto => 'tcp',
        port  => 22,
    }
}
