class role::bastionhost::2fa {
    system::role { 'bastionhost::2fa':
        description => 'Bastion host using two factor authentication',
    }

    include ::bastionhost
    include standard
    include base::firewall
    include role::backup::host

    backup::set {'home': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

}
