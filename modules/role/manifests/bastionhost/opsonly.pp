# bastion host just for ops members
class role::bastionhost::opsonly {
    system::role { 'bastionhost::opsonly':
        description => 'Bastion host restricted to the ops team',
    }

    include ::bastionhost
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host

    backup::set {'home': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

}
