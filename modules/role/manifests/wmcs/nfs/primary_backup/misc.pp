class role::wmcs::nfs::primary_backup::misc {
    system::role { $name:
        description => 'NFS shares primary backup (misc)',
    }
    include ::profile::standard
    include profile::wmcs::nfs::backup::primary::base
    include profile::wmcs::nfs::backup::primary::misc

    # TODO: since the introduction of cinder-backup here, the role name
    # is probably no longer accurate
    include profile::openstack::codfw1dev::rbd_cloudcontrol
    include profile::openstack::codfw1dev::cinder::backup
}
