# bastion host for all users
class role::bastionhost::general {

    system::role { 'bastionhost::general':
        description => 'Bastion host for all shell users',
    }

    include ::standard
    include ::base::firewall
    include ::bastionhost
    include ::profile::backup::host
    include ::profile::bastionhost::general
    include ::profile::scap::dsh  # Used by parsoid deployers
    backup::set {'home': }

}
