class role::wmcs::openstack::eqiad1::backups {
    system::role { $name: }

    # README: we like backups to be kind of offsite. The eqiad1 backups
    # are on the codfw DC.

    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::cloudceph::auth::deploy
    include profile::cloudceph::client::rbd_cloudbackup
    include profile::openstack::eqiad1::cinder::backup

    # Temporary, for experimentation:
    include profile::wmcs::backy2
}
