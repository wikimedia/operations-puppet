class role::wmcs::openstack::codfw1dev::backups {
    # README: we like backups to be kind of offsite. The eqiad1 backups
    # are on the codfw DC. Likewise, the codfw1dev backups are in the eqiad DC.
    # That's why this role is namespaced 'codfw1dev' but is meant to be applied to
    # servers in the eqiad DC.

    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::cloudceph::auth::deploy
    include profile::cloudceph::client::rbd_cloudbackup
    include profile::openstack::codfw1dev::cinder::backup
}
