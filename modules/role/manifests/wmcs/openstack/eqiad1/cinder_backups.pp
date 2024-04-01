# SPDX-License-Identifier: Apache-2.0
class role::wmcs::openstack::eqiad1::cinder_backups {
    system::role { $name: }

    # README: we like backups to be offsite. The eqiad1 cinder backups
    # are on the codfw DC. This requires us to override several hiera
    # settings at the host-level to avoid picking up dc-level config.

    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::cloudceph::auth::deploy
    include profile::cloudceph::client::rbd_cloudbackup
    include profile::wmcs::backy2
    include profile::openstack::eqiad1::envscripts
    include profile::wmcs::backup_cinder_volumes
}
