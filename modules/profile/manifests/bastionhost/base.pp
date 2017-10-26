# common settings for all bastion hosts
class profile::bastionhost::base {

    class{'::bastionhost'}
    include ::standard
    class{'::profile::backup::host'}

    backup::set {'home': }

    class{'::base::firewall'}


    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }


}