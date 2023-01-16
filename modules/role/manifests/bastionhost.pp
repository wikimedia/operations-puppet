# bastion host for all users
class role::bastionhost{
    system::role { 'bastionhost':
        description => 'Bastion host for all shell users',
    }

    include profile::base::production
    include profile::base::firewall
    include profile::backup::host

    ensure_packages(['mtr-tiny', 'traceroute', 'mosh'])

    # Used by parsoid deployers
    include ::profile::scap::dsh

    backup::set {'home': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '03',
        proto => 'tcp',
        port  => 'ssh',
    }
}
