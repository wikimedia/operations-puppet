# General use bastion host (All Users)
class profile::bastionhost::general {
    system::role { 'bastionhost::general':
        description => 'Bastion host for all shell users',
    }

    class{'::profile::bastionhost::base'}
    # Used by parsoid deployers
    class{'::profile::scap::dsh'}

}