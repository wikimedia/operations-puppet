# bastion host for all users
class profile::bastionhost::general {

    class { '::bastionhost': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

}
