# bastion host role
class role::bastionhost {
    system::role { 'bastionhost':
        description => 'Bastion',
    }

    include ::bastionhost

    ferm::service { 'bastion_ssh':
        proto => 'tcp',
        port  => 'ssh',
    }
}
