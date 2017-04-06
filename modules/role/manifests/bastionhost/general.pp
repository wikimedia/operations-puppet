# bastion host for all users
class role::bastionhost::general {
    system::role { 'bastionhost::general':
        description => 'Bastion host for all shell users',
    }

    include ::bastionhost
    include ::standard
    include ::base::firewall
    include ::profile::backup::host

    # Used by parsoid deployers
    include ::scap::dsh

    backup::set {'home': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

}
