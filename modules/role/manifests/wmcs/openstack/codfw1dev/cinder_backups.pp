# SPDX-License-Identifier: Apache-2.0
class role::wmcs::openstack::codfw1dev::cinder_backups {
    system::role { $name: }

    # README: we like backups to be offsite. The codfw1dev cinder backups
    # are in the eqiad DC. This requires us to override several hiera
    # settings at the host-level to avoid picking up dc-level config.

    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::cloudceph::auth::deploy
    include profile::cloudceph::client::rbd_cloudbackup
    include profile::wmcs::backy2
    include profile::openstack::codfw1dev::observerenv
    include profile::wmcs::backup_cinder_volumes
}
