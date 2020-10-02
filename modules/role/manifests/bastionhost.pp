# bastion host for all users
class role::bastionhost{
    system::role { 'bastionhost':
        description => 'Bastion host for all shell users',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host

    include ::profile::bastionhost::packages

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
