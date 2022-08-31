# SPDX-License-Identifier: Apache-2.0

# Backup servers running backy2 to backup VM drives
class role::wmcs::openstack::eqiad1::backy {
    system::role { $name: }
    include profile::base::production
    include profile::base::firewall

    # This installs ceph.conf and other ceph client things
    include profile::ceph::client::rbd_backy

    # We need openstack clients so we can enumerate VMs to back up
    include profile::openstack::eqiad1::clientpackages
    include profile::openstack::eqiad1::envscripts
    include profile::openstack::eqiad1::observerenv

    include profile::ceph::auth::deploy
    include profile::wmcs::backy2

    include profile::wmcs::backup_glance_images
}
