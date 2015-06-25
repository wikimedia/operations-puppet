# bastion host role
class role::bastionhost {
    system::role { 'bastionhost':
        description => 'Bastion',
    }

    include ::bastionhost
    include base::firewall

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

    backup::set {'home': }
}
