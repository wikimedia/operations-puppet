# bastion host for all users
class role::bastionhost::general {
    system::role { 'bastionhost::general':
        description => 'Bastion host for all shell users',
    }

    include ::bastionhost
    include ::standard
    include ::profile::base::firewall
    include ::profile::backup::host

    # Used by parsoid deployers

    include ::profile::scap::dsh

    backup::set {'home': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

    rsync::quickdatacopy { 'bast-home':
        ensure      => present,
        source_host => 'bast2001.wikimedia.org',
        dest_host   => 'bast2002.wikimedia.org',
        auto_sync   => false,
        module_path => '/home',
    }
}
