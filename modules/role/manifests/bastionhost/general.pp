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

    rsync::quickdatacopy { 'bastion-home':
      ensure      => present,
      auto_sync   => false,
      source_host => 'bast1001.wikimedia.org',
      dest_host   => 'bast1002.wikimedia.org',
      module_path => '/home',
    }

    if $::fqdn == "bast1001.wikimedia.org" {
        motd::script { 'inactive_warning':
            ensure   => $motd_ensure,
            priority => 1,
            content  => template('role/bastionhost/inactive.motd.erb'),
        }
    }
}
