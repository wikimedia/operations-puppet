class role::wmcs::openstack::eqiad1::backups {
    system::role { $name: }

    # README: we like backups to be kind of offsite. The eqiad1 backups
    # are on the codfw DC.

    include profile::base::production
    include profile::base::firewall
    include profile::ceph::auth::deploy
    include profile::ceph::client::rbd_cloudbackup
    include profile::openstack::eqiad1::cinder::backup
}
