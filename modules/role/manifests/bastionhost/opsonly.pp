# bastion host just for ops members
class role::bastionhost::opsonly {
    system::role { 'bastionhost::opsonly':
        description => 'Bastion host restricted to the ops team',
    }

    include ::standard
    include ::base::firewall
    include ::bastionhost
    inlcude ::profile::bastionhost::opsonly
    include ::profile::backup::host
    backup::set {'home': }
}
